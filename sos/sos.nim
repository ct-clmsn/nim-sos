#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
import ./bindings
import std/math
import std/strutils
import std/hashes
import macros

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

proc partitioner(global_nelems : int) : int =
    return int(ceil(float64(global_nelems) / float64(bindings.n_pes())))

type symarray*[T : SomeNumber] = object
    ## a symarrayuence type for SomeNumber values;
    ## the memory for every value in the symarrayuence
    ## is registered with libfabric for RDMA
    ## communications.
    ##
    owned : bool
    len : int
    data : ptr UncheckedArray[T]

proc newSymArray[T : SomeNumber]() : symarray[T] =
    return symarray[T]( owned : false, len : 0, data : nil )

proc newSymArray*[T : SomeNumber](nelem : int) : symarray[T] =
    ## creates a symarray[T] with 'sz' number of
    ## elements of type 'T'
    ##
    return symarray[T]( owned : true, len : nelem, data : bindings.alloc[T](sizeof(T) * nelem) )

proc newSymArray*[T : SomeNumber](elems: varargs[T]) : symarray[T] =
    ## creates a symarray[T] that has the same length
    ## as 'elems' and each value in the returned
    ## symarray[T] is equal to the values in 'elems'
    ##
    let nelem = cast[int](elems.len)
    var res = symarray[T]( owned : true, len : nelem, data : bindings.alloc[T](sizeof(T) * nelem) )
    for i in 0..<res.len: res.data[i] = elems[i]
    return res

proc freeSymArray*[T : SomeNumber](x : var symarray[T]) =
    ## manually frees a symarray[T]
    ##
    if x.owned:
        x.len = 0
        bindings.free[T](x.data)
        x.data = nil
        x.owned = false

proc `=destroy`*[T:SomeNumber](x : var symarray[T]) =
    ## frees a symarray[T] when it falls out
    ## of scope
    ##
    if x.owned:
        bindings.free[T](x.data)
        x.owned = false

proc `=sink`*[T:SomeNumber](a: var symarray[T], b: symarray[T]) =
    ## provides move assignment
    ##
    `=destroy`(a)
    # move assignment, optional.
    # Compiler is using `=destroy` and `copyMem` when not provided
    # 
    wasMoved(a)
    a.len = b.len
    a.data = b.data

proc `[]`*[T:SomeNumber](self:symarray[T], i: Natural): lent T =
    ## return a value at position 'i'
    ##
    assert cast[uint64](i) < self.len
    self.data[i]

proc `[]=`*[T:SomeNumber](self: var symarray[T]; i: Natural; y: sink T) =
    ## assign a value at position 'i' equal to
    ## the value 'y'
    ##
    assert i < self.len
    self.data[i] = y

proc `[]`*[T:SomeNumber](self: var symarray[T], s : Slice[T]) : seq[T] =
    assert( ((s.b-s.a) < self.len) and s.a > -1 and s.b < self.len )
    let L = abs(s.b-s.a)
    newSeq(result, L)
    for i in 0 .. L: result[i] = self.data[i+s.a]

proc `[]=`*[T:SomeNumber](self: var symarray[T], s : Slice[T], b : openarray[T]) =
    assert( (s.a > -1) and (s.b < self.len) and ((s.b-s.a) < b.len) )
    let L = s.b-s.a
    let minL = min(L, b.len)
    for i in 0 .. minL: self.data[i+s.a] = b[i]

proc len*[T:SomeNumber](self: symarray[T]): uint64 {.inline.} = self.len

iterator items*[T:SomeNumber](self : symarray[T]) : T =
    ## iterator over the elements in a symarray
    ##
    let rng = self.range
    for i in rng:
        yield self.data[i-rng.sp] 

iterator pairs*[T:SomeNumber](self : symarray[T]) : T =
    ## iterator returns pairs (index, value) over elements in a symarray
    ##
    let rng = self.range
    for i in rng.sp..rng.ep:
        yield (i, self.data[i-rng.sp])

proc distribute*[T : SomeNumber](src : symarray[T], num : Positive, spread=true) : seq[symarray[T]] =
    ## Splits a symarray[T] into num a sequence of symarray's;
    ## symarray's do not `own` their data.
    ##
    if num < 2:
        result = @[src]
        return

    result = newSeq[symarray[T]](num)

    var
        stride = src.len div num
        first = 0
        last = 0
        extra = src.len mod num

    if extra == 0 or spread == false:
        # Use an algorithm which overcounts the stride and minimizes reading limits.
        if extra > 0: inc(stride)
        for i in 0 ..< num:
            result[i].data = src.data + first
            result[i].len = min(src.len, first+stride)
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

proc put*[T : SomeNumber](src : var openarray[T], dst : symarray[T], pe : int) =
    ## synchronous put; transfers byte in `src` in the current process virtual address space to
    ## process `id` at address `dst` in the destination. Users must check for completion or invoke
    ## sym_wait. Do not modify the symarray before the transfer terminates
    ##
    bindings.put(dst.data, unsafeAddr(src), T.sizeof * src.len, pe)

proc get*[T : SomeNumber](dst : var openarray[T], src : symarray[T], pe : int) =
    ## synchronous get; transfers bytes in `src` in a remote process `id`'s virtual address space
    ## into the current process at address `dst`. Users must check for completion or invoke sym_wait.
    ## Do not modify the symarray before the transfer terminates
    ## 
    bindings.get(unsafeAddr(dst), src.data, T.sizeof * src.len, pe)

proc get*[T : SomeNumber](self : symarray[T], pe : int) : openarray[T] =
    result.setLen(self.len)
    bindings.get(result, self, pe)

proc nbput*[T : SomeNumber](src : var openarray[T], dst : symarray[T], pe : int) =
    ## asynchronous put; transfers byte in `src` in the current process virtual address space to
    ## process `id` at address `dst` in the destination. Users must check for completion or invoke
    ## sym_wait. Do not modify the symarray before the transfer terminates
    ##
    bindings.nbput(dst.data, unsafeAddr(src), T.sizeof * src.len, pe)

proc nbget*[T : SomeNumber](dst : var openarray[T], src : symarray[T], pe : int) =
    ## asynchronous get; transfers bytes in `src` in a remote process `id`'s virtual address space
    ## into the current process at address `dst`. Users must check for completion or invoke sym_wait.
    ## Do not modify the symarray before the transfer terminates
    ## 
    bindings.nbget(unsafeAddr(dst), src.data, T.sizeof * src.len, pe)

proc nbget*[T : SomeNumber](self : symarray[T], pe : int) : openarray[T] =
    result.setLen(self.len)
    bindings.get(result, self, pe)

type ModeKind* = enum
    blocking,
    nonblocking

proc put*[T : SomeNumber](mk : ModeKind, src : var openarray[T], dst : symarray[T], pe : int) =
    case mk:
    of blocking:
        put(src, dst, pe)
    of nonblocking:
        nbput(src, dst, pe)

proc get*[T : SomeNumber](mk : ModeKind, dst : var openarray[T], src : symarray[T], pe : int) =
    case mk:
    of blocking:
        get(dst, src, pe) 
    of nonblocking:
        nbget(dst, src, pe)

proc get*[T : SomeNumber](self : symarray[T], mk : ModeKind, pe : int) : openarray[T] =
    result.setLen(self.len)
    get(result, self, pe)

proc get*[T : SomeNumber](mk : ModeKind, self : symarray[T], pe : int) : openarray[T] =
    result.setLen(self.len)
    get(result, self, pe)

type ReductionKind* = enum
    minop,
    maxop,
    sumop,
    prodop

proc reduce*[T:SomeNumber](rk : ReductionKind, team : Team, dst : symarray[T], src : symarray[T] ) : T =
    case rk:
    of minop:
        result = bindings.min_reduce(team, dst.data, src.data, dst.len)
    of maxop:
        result = bindings.max_reduce(team, dst.data, src.data, dst.len)
    of sumop:
        result = bindings.sum_reduce(team, dst.data, src.data, dst.len)
    of prodop: 
        result = bindings.prod_reduce(team, dst.data, src.data, dst.len)

proc min*[T:SomeNumber](team : Team, dst : symarray[T], src : symarray[T]) : T =
    result = reduce(minop, team, dst, src)

proc max*[T:SomeNumber](team : Team, dst : symarray[T], src : symarray[T]) : T =
    result = reduce(maxop, team, dst, src)

proc sum*[T:SomeNumber](team : Team, dst : symarray[T], src : symarray[T]) : T =
    result = reduce(sumop, team, dst, src)

proc prod*[T:SomeNumber](team : Team, dst : symarray[T], src : symarray[T]) : T =
    result = reduce(prodop, team, dst, src)

proc broadcast*[T:SomeNumber](team : Team, dst : symarray[T], src : symarray[T], root: int) : int =
    result = bindings.broadcast(team, dst.data, src.data, dst.len, root)

proc alltoall*[T:SomeNumber](team : Team, dst : symarray[T], src : symarray[T]) : int =
    result = bindings.alltoall(team, dst.data, src, dst.len)

proc fence*() =
    bindings.fence()

proc quiet*() =
    bindings.quiet()

proc barrier*() : int =
    bindings.barrier_all()

template sosBlock*(body : untyped) =
    bindings.ini()
    block:
        body
    bindings.fin()

type symint* = ptr int
type symint8* = ptr int8
type symint16* = ptr int16
type symint32* = ptr int32
type symint64* = ptr int64

type symuint* = ptr uint
type symuint8* = ptr uint8
type symuint16* = ptr uint16
type symuint32* = ptr uint32
type symuint64* = ptr uint64

type symfloat* = ptr float
type symfloat32* = ptr float32
type symfloat64* = ptr float64

type SymmetricInt* = symint | symint8 | symint16 | symint32 | symint64
type SymmetricUInt* = symuint | symuint8 | symuint16 | symuint32 | symuint64
type SymmetricFloat* = symfloat | symfloat32 | symfloat64

type SymmetricNumber* = SymmetricInt | SymmetricUInt | SymmetricFloat

converter toStr*(x : symint) : string =
   result = cast[ptr int](x)[].intToStr

converter toStr*(x : symint8) : string =
   let l = cast[ptr int8](x)[]
   result = $l

converter toStr*(x : symint16) : string =
   let l = cast[ptr int16](x)[]
   result = $l

converter toStr*(x : symint32) : string =
   let l = cast[ptr int32](x)[]
   result = $l

converter toStr*(x : symint64) : string =
   let l = cast[ptr int64](x)[]
   result = $l

converter toStr*(x : symuint) : string =
   result = cast[ptr int](x)[].intToStr

converter toStr*(x : symuint8) : string =
   let l = cast[ptr int8](x)[]
   result = $l

converter toStr*(x : symuint16) : string =
   let l = cast[ptr int16](x)[]
   result = $l

converter toStr*(x : symuint32) : string =
   let l = cast[ptr int32](x)[]
   result = $l

converter toStr*(x : symuint64) : string =
   let l = cast[ptr int64](x)[]
   result = $l

converter toStr*(x : symfloat) : string =
   var l = cast[ptr float](x)[]
   result = $l

converter toStr*(x : symfloat32) : string =
   var l = cast[ptr float32](x)[]
   result = $l

template symoperators(typa : typedesc, typb:typedesc) =
   proc add*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] + y

   proc sub*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] - y

   proc mul*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] * y

   proc sto*(x:typa, y:typb) =
      cast[ptr typb](x)[] = y

template isymoperators(typa : typedesc, typb:typedesc) =
   proc `div`*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] div y

   proc `mod`*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] mod y

template fsymoperators(typa : typedesc, typb:typedesc) =
   proc `/`*(x: typa, y:typb) : typb=
      result = cast[ptr typb](x)[] / y

symoperators(symint, int)
symoperators(symint8, int8)
symoperators(symint16, int16)
symoperators(symint32, int32)
symoperators(symint64, int64)

symoperators(symuint, uint)
symoperators(symuint8, uint8)
symoperators(symuint16, uint16)
symoperators(symuint32, uint32)
symoperators(symuint64, uint64)

isymoperators(symint, int)
isymoperators(symint8, int8)
isymoperators(symint16, int16)
isymoperators(symint32, int32)
isymoperators(symint64, int64)

isymoperators(symuint, uint)
isymoperators(symuint8, uint8)
isymoperators(symuint16, uint16)
isymoperators(symuint32, uint32)
isymoperators(symuint64, uint64)

symoperators(symfloat, float)
symoperators(symfloat32, float32)
symoperators(symfloat64, float64)

fsymoperators(symfloat, float)
fsymoperators(symfloat32, float32)
fsymoperators(symfloat64, float64)

macro sosSymmetricScalars*(body : untyped) : untyped =
   # sosSymmetricVars:
   #    var a : int
   #    var b : float
   #    var
   #       cee : int
   #       d : float
   #
   # cee = 4
   # echo "value", cee
   #
   # var dee = 1
   # var eff = 2
   # echo dee
   # echo eff
   #
   # let types : seq[string] = @["int", "int8", "int16", "int32", "int64", "float", "float32", "float64", "uint", "uint8", "uint16", "uint32"]
   #
   if body.kind != nnkStmtList:
        error("sosStatic expects nnkBlockStmt")

   result = newStmtList()

   for child in body:
      if child.kind == nnkVarSection:
         for c in child:
            # c[0] = variable name
            # c[1] = variable type
            #
            if c[1].kind != nnkEmpty:
               let varname : string = c[0].strVal
               let typename : string = c[1].strVal
               var ctype : string
               var nimtype : string
               case typename:
                  of "symint":
                     ctype = "int"
                     nimtype = "int"
                  of "symint8":
                     ctype = "int"
                     nimtype = "int8"
                  of "symint16":
                     ctype = "int"
                     nimtype = "int16"
                  of "symint32":
                     ctype = "int"
                     nimtype = "int32"
                  of "symint64":
                     ctype = "int64_t"
                     nimtype = "int64"
                  of "symuint":
                     ctype = "unsigned int"
                     nimtype = "uint"
                  of "symuint8":
                     ctype = "uint8_t"
                     nimtype = "uint8"
                  of "symuint16":
                     ctype = "uint16_t"
                     nimtype = "uint16"
                  of "symuint32":
                     ctype = "uint32_t"
                     nimtype = "uint32"
                  of "symuint64":
                     ctype = "uint64_t"
                     nimtype = "uint64"
                  of "symfloat":
                     ctype = "float"
                     nimtype = "float"
                  of "symfloat32":
                     ctype = "float"
                     nimtype = "float32"
                  of "symfloat64":
                     ctype = "double"
                     nimtype = "float64"
                  else:
                     error("***sosStatic*** Found Error -> Variable: " & varname & "'s type not SomeNumber; type is " & typename)

               let pragmaStr : string = " {.codegenDecl: \"static $# $# \" .}"
               let varnamehashstr : string = intToStr(hash(varname))
               let varnamehashvar : string = varname & varnamehashstr & varname
               let fullStr : string = "var " & varnamehashvar & pragmaStr & " : " & nimtype
               let symfullStr : string = "var " & varname & " : " & typename & " = unsafeAddr(" & varnamehashvar & ")"
               result.add( parseStmt(fullStr) )
               result.add( parseStmt(symfullStr) )
