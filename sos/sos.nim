#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
import ./bindings
import std/math

let WORLD* = bindings.TEAM_WORLD 
let SHARED* = bindings.TEAM_SHARED

proc ini*() =
    bindings.ini()

proc fin*() =
    bindings.fin()

proc npes() : uint32 =
    result = bindings.n_pes()

proc mype() : uint32 =
    result = bindings.my_pe()

proc partitionSizer(global_nelems : int) : int =
    return int(ceil(float64(global_nelems) / float64(bindings.n_pes())))

type symseq*[T : SomeNumber] = object
    ## a symsequence type for SomeNumber values;
    ## the memory for every value in the symsequence
    ## is registered with libfabric for RDMA
    ## communications.
    ##
    owned : bool
    len : int
    data : ptr UncheckedArray[T]

proc newSymSeq[T : SomeNumber]() : symseq[T] =
    return symseq[T]( owned : false, len : 0, data : nil )

proc newSymSeq*[T : SomeNumber](nelem : int) : symseq[T] =
    ## creates a symseq[T] with 'sz' number of
    ## elements of type 'T'
    ##
    return symseq[T]( owned : true, len : nelem, data : bindings.alloc[T](sizeof(T) * nelem) )

proc newSymSeq*[T : SomeNumber](elems: varargs[T]) : symseq[T] =
    ## creates a symseq[T] that has the same length
    ## as 'elems' and each value in the returned
    ## symseq[T] is equal to the values in 'elems'
    ##
    let nelem = cast[int](elems.len)
    var res = symseq[T]( owned : true, len : nelem, data : bindings.alloc[T](sizeof(T) * nelem) )
    for i in 0..<res.len: res.data[i] = elems[i]
    return res

proc freeSymSeq*[T : SomeNumber](x : var symseq[T]) =
    ## manually frees a symseq[T]
    ##
    if x.owned:
        x.len = 0
        bindings.free[T](x.data)
        x.data = nil
        x.owned = false

proc `=destroy`*[T:SomeNumber](x : var symseq[T]) =
    ## frees a symseq[T] when it falls out
    ## of scope
    ##
    if x.owned:
        bindings.free[T](x.data)
        x.owned = false

proc `=sink`*[T:SomeNumber](a: var symseq[T], b: symseq[T]) =
    ## provides move assignment
    ##
    `=destroy`(a)
    # move assignment, optional.
    # Compiler is using `=destroy` and `copyMem` when not provided
    # 
    wasMoved(a)
    a.len = b.len
    a.data = b.data

proc `[]`*[T:SomeNumber](self:symseq[T], i: Natural): lent T =
    ## return a value at position 'i'
    ##
    assert cast[uint64](i) < self.len
    self.data[i]

proc `[]=`*[T:SomeNumber](self: var symseq[T]; i: Natural; y: sink T) =
    ## assign a value at position 'i' equal to
    ## the value 'y'
    ##
    assert i < self.len
    self.data[i] = y

proc `[]`*[T:SomeNumber](self: var symseq[T], s : Slice[T]) : seq[T] =
    assert( ((s.b-s.a) < self.len) and s.a > -1 and s.b < self.len )
    let L = abs(s.b-s.a)
    newSeq(result, L)
    for i in 0 .. L: result[i] = self.data[i+s.a]

proc `[]=`*[T:SomeNumber](self: var symseq[T], s : Slice[T], b : openarray[T]) =
    assert( (s.a > -1) and (s.b < self.len) and ((s.b-s.a) < b.len) )
    let L = s.b-s.a
    let minL = min(L, b.len)
    for i in 0 .. minL: self.data[i+s.a] = b[i]

iterator items[T:SomeNumber](self : symseq[T]) : T =
    for i in 0..self.len:
        yield self[i]

proc len*[T:SomeNumber](self: symseq[T]): uint64 {.inline.} = self.len

proc range*[T:SomeNumber](self : symseq[T]) : range[uint64] {.inline.} = 0..<self.len

proc indices*[T:SomeNumber](self : symseq[T]) : range[uint64] {.inline.} = 0..<self.len

iterator items*[T](self : symseq[T]) : T =
    ## iterator over the elements in a symseq
    ##
    let rng = self.range
    for i in rng:
        yield self.data[i-rng.sp] 

iterator pairs*[T](self : symseq[T]) : T =
    ## iterator returns pairs (index, value) over elements in a symseq
    ##
    let rng = self.range
    for i in rng.sp..rng.ep:
        yield (i, self.data[i-rng.sp])

proc distribute*[T : SomeNumber](src : symseq[T], num : Positive, spread=true) : seq[symseq[T]] =
    ## Splits a symseq[T] into num a sequence of symseq's;
    ## symseq's do not `own` their data.
    ##
    if num < 2:
        result = @[s]
        return

    result = newSeq[symseq[T]](num)

    var
        stride = s.len div num
        first = 0
        last = 0
        extra = s.len mod num

    if extra == 0 or spread == false:
        # Use an algorithm which overcounts the stride and minimizes reading limits.
        if extra > 0: inc(stride)
        for i in 0 ..< num:
            result[i].data = src.data + first
            result[i].len = min(s.len, first+stride)
            result[i].owned = false
            first += stride
    else:
        # Use an undercounting algorithm which *adds* the remainder each iteration.
        for i in 0 ..< num:
            last = first + stride
            if extra > 0:
                extra -= 1
                inc(last)
            result[i].data = src.data + first
            result[i].len = last-first
            result[i].owned = false
            first = last    

proc put*[T : SomeNumber](src : var ownedarray[T], dst : symseq[T], pe : int) =
    ## synchronous put; transfers byte in `src` in the current process virtual address space to
    ## process `id` at address `dst` in the destination. Users must check for completion or invoke
    ## sym_wait. Do not modify the symseq before the transfer terminates
    ##
    bindings.put(dst.data, unsafeAddr(src), T.sizeof * src.len, pe)

proc get*[T : SomeNumber](dst : var ownedarray[T], src : symseq[T], pe : int) =
    ## synchronous get; transfers bytes in `src` in a remote process `id`'s virtual address space
    ## into the current process at address `dst`. Users must check for completion or invoke sym_wait.
    ## Do not modify the symseq before the transfer terminates
    ## 
    bindings.get(unsafeAddr(dst), src.data, T.sizeof * src.len, pe)

proc get*[T : SomeNumber](self : symseq[T], pe : int) : openarray[T] =
    result.setLen(self.len)
    bindings.get(result, self, pe)

proc nbput*[T : SomeNumber](src : var ownedarray[T], dst : symseq[T], pe : int) =
    ## asynchronous put; transfers byte in `src` in the current process virtual address space to
    ## process `id` at address `dst` in the destination. Users must check for completion or invoke
    ## sym_wait. Do not modify the symseq before the transfer terminates
    ##
    bindings.nbput(dst.data, unsafeAddr(src), T.sizeof * src.len, pe)

proc nbget*[T : SomeNumber](dst : var ownedarray[T], src : symseq[T], pe : int) =
    ## asynchronous get; transfers bytes in `src` in a remote process `id`'s virtual address space
    ## into the current process at address `dst`. Users must check for completion or invoke sym_wait.
    ## Do not modify the symseq before the transfer terminates
    ## 
    bindings.nbget(unsafeAddr(dst), src.data, T.sizeof * src.len, pe)

proc nbget*[T : SomeNumber](self : symseq[T], pe : int) : openarray[T] =
    result.setLen(self.len)
    bindings.get(result, self, pe)

type ModeKind* = enum
    blocking,
    nonblocking

proc put*[T : SomeNumber](mk : ModeKind, src : var ownedarray[T], dst : symseq[T], pe : int) =
    case mk:
    of blocking:
        put(src, dst, pe)
    of nonblocking:
        nbput(src, dst, pe)

proc get*[T : SomeNumber](mk : ModeKind, dst : var ownedarray[T], src : symseq[T], pe : int) =
    case mk:
    of blocking:
        get(dst, src, pe) 
    of nonblocking:
        nbget(dst, src, pe)

proc get*[T : SomeNumber](self : symseq[T], mk : ModeKind, pe : int) : openarray[T] =
    result.setLen(self.len)
    get(result, self, pe)

proc get*[T : SomeNumber](mk : ModeKind, self : symseq[T], pe : int) : openarray[T] =
    result.setLen(self.len)
    get(result, self, pe)

type ReductionKind* = enum
    minop,
    maxop,
    sumop,
    prodop

proc reduce*[T:SomeNumber](rk : ReductionKind, team : Team, dst : symseq[T], src : symseq[T] ) : T =
    case rk:
    of minop:
        result = bindings.min_reduce(team, dst.data, src.data, dst.len)
    of maxop:
        result = bindings.max_reduce(team, dst.data, src.data, dst.len)
    of sumop:
        result = bindings.sum_reduce(team, dst.data, src.data, dst.len)
    of prodop: 
        result = bindings.prod_reduce(team, dst.data, src.data, dst.len)

proc min*[T:SomeNumber](team : Team, dst : symseq[T], src : symseq[T]) : T =
    result = reduce(minop, team, dst, src)

proc max*[T:SomeNumber](team : Team, dst : symseq[T], src : symseq[T]) : T =
    result = reduce(maxop, team, dst, src)

proc sum*[T:SomeNumber](team : Team, dst : symseq[T], src : symseq[T]) : T =
    result = reduce(sumop, team, dst, src)

proc prod*[T:SomeNumber](team : Team, dst : symseq[T], src : symseq[T]) : T =
    result = reduce(prodop, team, dst, src)

proc broadcast*[T:SomeNumber](team : Team, dst : symseq[T], src : symseq[T], root: int) : int =
    result = bindings.broadcast(team, dst.data, src.data, dst.len, root)

proc alltoall*[T:SomeNumber](team : Team, dst : symseq[T], src : symseq[T]) : int =
    result = bindings.alltoall(team, dst.data, src, dst.len)

proc fence*() =
    bindings.fence()

proc quiet*() =
    bindings.quiet()

template sosBlock*(body : untyped) =
    bindings.ini()
    block:
        body
    bindings.fin()


