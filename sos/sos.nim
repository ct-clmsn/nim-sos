#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
{.deadCodeElim: on.}
import ./bindings
import std/posix
import std/math
import std/strutils
import std/hashes
import macros

type symscalar*[T:SomeNumber] = ptr T

type symint* = symscalar[cint]
type symint8* = symscalar[cshort]
type symint16* = symscalar[cshort]
type symint32* = symscalar[cint]
type symint64* = symscalar[clonglong]

type symuint* = symscalar[cuint]
type symuint8* = symscalar[cushort]
type symuint16* = symscalar[cushort]
type symuint32* = symscalar[cuint]
type symuint64* = symscalar[culonglong]

type symfloat* = symscalar[cfloat]
type symfloat32* = symscalar[cfloat]
type symfloat64* = symscalar[cdouble]

type SomeSymmetricInt* = symint | symint8 | symint16 | symint32 | symint64
type SomeSymmetricUInt* = symuint | symuint8 | symuint16 | symuint32 | symuint64
type SomeSymmetricFloat* = symfloat | symfloat32 | symfloat64

type SomeSymmetricNumber* = SomeSymmetricInt | SomeSymmetricUInt | SomeSymmetricFloat

converter toStr*(x : symint) : string =
   result = cast[ptr cint](x)[].intToStr

converter toStr*(x : symint8) : string =
   let l = cast[ptr cshort](x)[]
   result = $l

#converter toStr*(x : symint16) : string =
#   let l = cast[ptr cshort](x)[]
#   result = $l

#converter toStr*(x : symint32) : string =
#   let l = cast[ptr cint](x)[]
#   result = $l

converter toStr*(x : symint64) : string =
   let l = cast[ptr clonglong](x)[]
   result = $l

converter toStr*(x : symuint) : string =
   result = cast[ptr int](x)[].intToStr

converter toStr*(x : symuint8) : string =
   let l = cast[ptr cushort](x)[]
   result = $l

#converter toStr*(x : symuint16) : string =
#   let l = cast[ptr cushort](x)[]
#   result = $l

#converter toStr*(x : symuint32) : string =
#   let l = cast[ptr cuint](x)[]
#   result = $l

converter toStr*(x : symuint64) : string =
   let l = cast[ptr culonglong](x)[]
   result = $l

converter toStr*(x : symfloat) : string =
   var l = cast[ptr cfloat](x)[]
   result = $l

#converter toStr*(x : symfloat32) : string =
#   var l = cast[ptr cfloat](x)[]
#   result = $l

converter toStr*(x : symfloat64) : string =
   var l = cast[ptr cdouble](x)[]
   result = $l

converter toStr*[T:SomeNumber](x : symscalar[T]) : string =
    result = $x

template symoperators(typa : typedesc, typb:typedesc) =
   proc add*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] + y

   proc sub*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] - y

   proc mul*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] * y

   proc sto*(x:typa, y:typb) =
      cast[ptr typb](x)[] = y

   proc read*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[]

template isymoperators(typa : typedesc, typb:typedesc) =
   proc `div`*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] div y

   proc `mod`*(x:typa, y:typb) : typb =
      result = cast[ptr typb](x)[] mod y

template fsymoperators(typa : typedesc, typb:typedesc) =
   proc `/`*(x: typa, y:typb) : typb=
      result = cast[ptr typb](x)[] / y

   proc `div`*(x:typa, y:typb) : typb =
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

type symarray*[T] = object
    ## a symarrayuence type for SomeNumber values;
    ## the memory for every value in the symarrayuence
    ## is registered with libfabric for RDMA
    ## communications.
    ##
    owned : bool
    len : int
    data : ptr T

type symarrayint* = symarray[cint]
type symarrayint16* = symarray[cshort]
type symarrayint32* = symarray[cint]
type symarrayint64* = symarray[clong]
type symarrayuint* = symarray[cuint]
type symarrayuint16* = symarray[cushort]
type symarrayuint32* = symarray[cuint]
type symarrayuint64* = symarray[culong]
type symarrayfloat* = symarray[cfloat]
type symarraydouble* = symarray[cdouble]

template `+`*[T](p: ptr T, off: int): ptr T =
   cast[ptr type(p[])](cast[ByteAddress](p) +% off * sizeof(p[]))

proc newSymArrayImpl[T, F](nelem:int) : symarray[F] =
    result = symarray[F]( owned : false, len : 0, data : bindings.alloc[F](sizeof(F) * nelem) )

proc newSymArrayImpl[T,F](elems: varargs[T]) : symarray[F] =
    let nelem = cast[int](elems.len)
    result = symarray[F]( owned : true, len : nelem, data : bindings.alloc[F](sizeof(F) * nelem))
    for i in 0..<result.len:
        (result.data+i)[] = cast[F](elems[i])

proc newSymArray*[T:int](nelem : int) : symarray[cint] =
    result = newSymArrayImpl[int, cint](nelem)

proc newSymArrayInt*(nelem : int) : symarrayint =
    result = newSymArrayImpl[int, cint](nelem)

proc newSymArrayInt*(elems: varargs[int]) : symarrayint =
    result = newSymArrayImpl[int, cint](elems)

proc newSymArray*[T:int](elems: varargs[T]) : symarray[cint] =
    result = newSymArrayImpl[int, cint](elems)

# cint16
#proc newSymArray*[T:int16](nelem : int) : symarray[cshort] =
#    result = newSymArrayImpl[int16, cshort](nelem)

proc newSymArrayInt16*(nelem : int) : symarrayint16 =
    result = newSymArrayImpl[int16, cshort](nelem)

proc newSymArrayInt16*(elems: varargs[int16]) : symarrayint16 =
    result = newSymArrayImpl[int16, cshort](elems)

#proc newSymArray*[T:int16](elems: varargs[T]) : symarray[cshort] =
#    result = newSymArrayImpl[int16, cshort](elems)

#cint64
#proc newSymArray*[T:int64](nelem : int) : symarray[clong] =
#    result = newSymArrayImpl[int64, clong](nelem)

proc newSymArrayInt64*(nelem : int) : symarrayint64 =
    result = newSymArrayImpl[int64, clong](nelem)

proc newSymArrayInt64*(elems: varargs[int64]) : symarrayint64 =
    result = newSymArrayImpl[int64, clong](elems)

#proc newSymArray*[T:int64](elems: varargs[T]) : symarray[clong] =
#    result = newSymArrayImpl[int64, clong](elems)

# cuint8
#proc newSymArray*[T:uint](nelem : int) : symarray[cuint] =
#    result = newSymArrayImpl[uint, cuint](nelem)

proc newSymArrayUInt*(nelem : int) : symarrayuint =
    result = newSymArrayImpl[uint, cuint](nelem)

proc newSymArrayUInt*(elems: varargs[uint]) : symarrayuint =
    result = newSymArrayImpl[uint, cuint](elems)

#proc newSymArray*[T:uint](elems: varargs[T]) : symarray[cuint] =
#    result = newSymArrayImpl[uint, cuint](elems)

# cuint16
#proc newSymArray*[T:uint16](nelem : int) : symarray[cushort] =
#    result = newSymArrayImpl[uint16, cushort](nelem)

proc newSymArrayUInt16*(nelem : int) : symarrayuint16 =
    result = newSymArrayImpl[uint16, cushort](nelem)

proc newSymArrayUInt16*(elems: varargs[uint16]) : symarrayuint16 =
    result = newSymArrayImpl[uint16, cushort](elems)

#proc newSymArray*[T:uint16](elems: varargs[T]) : symarray[cushort] =
#    result = newSymArrayImpl[uint16, cushort](elems)

#cuint64
#proc newSymArray*[T:int64](nelem : int) : symarray[clong] =
#    result = newSymArrayImpl[int64, clong](nelem)

proc newSymArrayUInt64*(nelem : int) : symarrayuint64 =
    result = newSymArrayImpl[uint64, culong](nelem)

proc newSymArrayUInt64*(elems: varargs[uint64]) : symarrayuint64 =
    result = newSymArrayImpl[uint64, culong](elems)

#proc newSymArray*[T:uint64](elems: varargs[T]) : symarray[culong] =
#    result = newSymArrayImpl[uint64, culong](elems)

#cfloat
#proc newSymArray*[T:float](nelem : int) : symarray[cfloat] =
#    result = newSymArrayImpl[int16, cfloat](nelem)

proc newSymArrayFloat*(nelem : int) : symarrayfloat =
    result = newSymArrayImpl[float, cfloat](nelem)

proc newSymArrayFloat*(elems: varargs[float]) : symarrayfloat =
    result = newSymArrayImpl[float, cfloat](elems)

#proc newSymArray*[T:float](elems: varargs[T]) : symarray[cfloat] =
#    result = newSymArrayImpl[float, cfloat](elems)

#cdouble
#proc newSymArray*[T:float64](nelem : int) : symarray[cdouble] =
#    result = newSymArrayImpl[float64, cdouble](nelem)

#proc newSymArrayDouble*(nelem : int) : symarraydouble =
#    result = newSymArrayImpl[float64, cdouble](nelem)

proc newSymArrayDouble*(elems: varargs[float64]) : symarraydouble =
    result = newSymArrayImpl[float64, cdouble](elems)

proc newSymArrayDouble*[T:float64](elems: varargs[T]) : symarray[cdouble] =
    result = newSymArrayImpl[float64, cdouble](elems)

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
        bindings.free[T]( x.data )
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

proc `=copy`*[T:SomeNumber](a: var symarray[T], b: symarray[T]) =
   if a.data == b.data: return
   if a.len != b.len:
      error("unable to copy symarray, a.len != b.len")
   else:
      `=destroy`(a)
      wasMoved(a)
      a.len = b.len
      a.owned = b.owned
      a.data = b.data
      if b.data != nil:
         for i in 0..<a.len: (a.data+i)[] = (b.data+i)[]
    
proc `[]`*[T:SomeNumber](self:symarray[T], i: Natural): lent T =
    ## return a value at position 'i'
    ##
    assert cast[int](i) > 0 and cast[int](i) < self.len
    (self.data+i)[]

proc `[]=`*[T:SomeNumber](self: var symarray[T]; i: Natural; y: sink T) =
    ## assign a value at position 'i' equal to
    ## the value 'y'
    ##
    assert cast[int](i) > 0 and cast[int](i) < self.len
    (self.data+i)[] = y

proc `[]`*[T:SomeNumber](self: var symarray[T], s : Slice[T]) : seq[T] =
    assert( ((s.b-s.a) < self.len) and s.a > -1 and s.b < self.len )
    let L = abs(s.b-s.a)
    newSeq(result, L)
    for i in 0 .. L: result[i] = (self.data+i+s.a)[]

proc `[]=`*[T:SomeNumber](self: var symarray[T], s : Slice[T], b : openArray[T]) =
    assert( (s.a > -1) and (s.b < self.len) and ((s.b-s.a) < b.len) )
    let L = s.b-s.a
    let minL = min(L, b.len)
    for i in 0 .. minL: (self.data+i+s.a)[] = b[i]

proc len*[T:SomeNumber](self: symarray[T]): uint64 {.inline.} = self.len

iterator items*[T:SomeNumber](self : symarray[T]) : T =
    ## iterator over the elements in a symarray
    ##
    let rng = self.range
    for i in rng:
        yield (self.data+i-rng.sp)[] 

iterator pairs*[T:SomeNumber](self : symarray[T]) : T =
    ## iterator returns pairs (index, value) over elements in a symarray
    ##
    let rng = self.range
    for i in rng.sp..rng.ep:
        yield (i, (self.data+i-rng.sp)[])

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

type symptrarr[T : SomeNumber] = ptr T

#type symsarray*[ I : static[int], T : SomeNumber] = tuple[ nelem : int, data : symptrarr[T] ]
#
type symsarray*[ I : static[int], T : SomeNumber] = tuple[ nelem : int, data : symptrarr[T] ]

proc len*[I : static[int], T : SomeNumber](self: symsarray[I, T]): int {.inline.} = self.nelem

proc `[]`*[I : static[int], T : SomeNumber](self:symsarray[I, T], i: Natural): lent T =
    ## return a value at position 'i'
    ##
    assert cast[int](i) < self.nelem
    (self.data+i)[]

proc `[]=`*[I : static[int], T : SomeNumber](self: var symsarray[I, T]; i: Natural; y: sink T) =
    ## assign a value at position 'i' equal to
    ## the value 'y'
    ##
    assert i < self.len
    (self.data+i)[] = y

proc `[]`*[I : static[int], T : SomeNumber](self: var symsarray[I, T], s : Slice[T]) : seq[T] =
    assert( ((s.b-s.a) < self.len) and s.a > -1 and s.b < self.len )
    let L = abs(s.b-s.a)
    newSeq(result, L)
    for i in 0 .. L: result[i] = (self.data+i+s.a)[]

proc `[]=`*[I : static[int], T : SomeNumber](self: var symsarray[I, T], s : Slice[T], b : openArray[T]) =
    assert( (s.a > -1) and (s.b < self.len) and ((s.b-s.a) < b.len) )
    let L = s.b-s.a
    let minL = min(L, b.len)
    for i in 0 .. minL: (self.data+i+s.a)[] = b[i]

iterator items*[I : static[int], T : SomeNumber](self : symsarray[I, T]) : T =
    ## iterator over the elements in a symarray
    ##
    let rng = 0..<self.len
    for i in rng:
        yield (self.data+i-rng.sp)[] 

iterator pairs*[I : static[int], T : SomeNumber](self : symsarray[I, T]) : T =
    ## iterator returns pairs (index, value) over elements in a symarray
    ##
    let rng = 0..<self.len
    for i in rng.sp..rng.ep:
        yield (i, (self.data+i-rng.sp)[])

proc distribute*[I : static[int]; T : SomeNumber](src : symsarray[I, T], num : Positive, spread=true) : seq[symarray[T]] =
    ## Splits a symarray[T] into num a sequence of symarray's;
    ## symarray's do not `own` their data.
    ##
    if num < 2:
        result = @[src]
        return

    result = newSeq[symsarray[T]](num)

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

proc put*[I : static[int], T : SomeNumber](src : var openArray[T], dst : symsarray[I, T], pe : int) =
    ## synchronous put; transfers byte in `src` in the current process virtual address space to
    ## process `id` at address `dst` in the destination. Users must check for completion or invoke
    ## sym_wait. Do not modify the symarray before the transfer terminates
    ##
    bindings.put(dst.data, unsafeAddr(src), T.sizeof * src.len, pe)

proc get*[I : static[int], T : SomeNumber](dst : var openArray[T], src : symsarray[I, T], pe : int) =
    ## synchronous get; transfers bytes in `src` in a remote process `id`'s virtual address space
    ## into the current process at address `dst`. Users must check for completion or invoke sym_wait.
    ## Do not modify the symarray before the transfer terminates
    ## 
    bindings.get(unsafeAddr(dst), src.data, T.sizeof * src.len, pe)

proc get*[I : static[int], T : SomeNumber](self : symsarray[I, T], pe : int) : openArray[T] =
    result.setLen(self.len)
    bindings.get(result, self, pe)

proc nbput*[I : static[int], T : SomeNumber](src : var openArray[T], dst : symsarray[I, T], pe : int) =
    ## asynchronous put; transfers byte in `src` in the current process virtual address space to
    ## process `id` at address `dst` in the destination. Users must check for completion or invoke
    ## sym_wait. Do not modify the symarray before the transfer terminates
    ##
    bindings.nbput(dst.data, unsafeAddr(src), T.sizeof * src.len, pe)

proc nbget*[I : static[int], T : SomeNumber](dst : var openArray[T], src : symsarray[I, T], pe : int) =
    ## asynchronous get; transfers bytes in `src` in a remote process `id`'s virtual address space
    ## into the current process at address `dst`. Users must check for completion or invoke sym_wait.
    ## Do not modify the symarray before the transfer terminates
    ## 
    bindings.nbget(unsafeAddr(dst), src.data, T.sizeof * src.len, pe)

### beg -> block to remove when matrix, and tensor are ready
type SomeSymmetricArray = symarray[SomeNumber]

type SomeSymmetric* = SomeSymmetricNumber | SomeSymmetricArray
### end -> block to remove when matrix, and tensor are ready

let WORLD* = bindings.TEAM_WORLD
let SHARED* = bindings.TEAM_SHARED

proc ini*() =
    bindings.ini()

proc fin*() =
    bindings.fin()

proc npes*() : uint32 =
    result = bindings.n_pes()

proc mype*() : uint32 =
    result = bindings.my_pe()

proc partitioner(global_nelems : int) : int =
    return int(ceil(float64(global_nelems) / float64(bindings.n_pes())))

proc put*[T : SomeNumber](src : var openArray[T], dst : symarray[T], pe : int) =
    ## synchronous put; transfers byte in `src` in the current process virtual address space to
    ## process `id` at address `dst` in the destination. Users must check for completion or invoke
    ## sym_wait. Do not modify the symarray before the transfer terminates
    ##
    bindings.put(dst.data, unsafeAddr(src), T.sizeof * src.len, pe)

proc get*[T : SomeNumber](dst : var openArray[T], src : symarray[T], pe : int) =
    ## synchronous get; transfers bytes in `src` in a remote process `id`'s virtual address space
    ## into the current process at address `dst`. Users must check for completion or invoke sym_wait.
    ## Do not modify the symarray before the transfer terminates
    ## 
    bindings.get(unsafeAddr(dst), src.data, T.sizeof * src.len, pe)

proc get*[T : SomeNumber](self : symarray[T], pe : int) : openArray[T] =
    result.setLen(self.len)
    bindings.get(result, self, pe)

proc nbput*[T : SomeNumber](src : var openArray[T], dst : symarray[T], pe : int) =
    ## asynchronous put; transfers byte in `src` in the current process virtual address space to
    ## process `id` at address `dst` in the destination. Users must check for completion or invoke
    ## sym_wait. Do not modify the symarray before the transfer terminates
    ##
    bindings.nbput(dst.data, unsafeAddr(src), T.sizeof * src.len, pe)

proc nbget*[T : SomeNumber](dst : var openArray[T], src : symarray[T], pe : int) =
    ## asynchronous get; transfers bytes in `src` in a remote process `id`'s virtual address space
    ## into the current process at address `dst`. Users must check for completion or invoke sym_wait.
    ## Do not modify the symarray before the transfer terminates
    ## 
    bindings.nbget(unsafeAddr(dst), src.data, T.sizeof * src.len, pe)

type ModeKind* = enum
    blocking,
    nonblocking

proc put*[T : SomeNumber](mk : ModeKind, src : var openArray[T], dst : symarray[T], pe : int) =
    case mk:
    of blocking:
        put(src, dst, pe)
    of nonblocking:
        nbput(src, dst, pe)

template sput(typa : typedesc , typb: typedesc) =
    proc put*[T : typa, F : typb](src : var T, dst : F, pe : int) =
        bindings.put(dst, src.addr, T.sizeof * src.len, pe)

    proc nbput*[T : typa, F : typb](src : var T, dst : F, pe : int) =
        bindings.nbput(dst, src.addr, T.sizeof * src.len, pe)

    proc put*[T : typa, F : typb](mk : ModeKind, src : var T, dst : F, pe : int) =
        case mk:
        of blocking:
            put(src, dst, pe)
        of nonblocking:
            nbput(src, dst, pe)

sput(int, symint)
sput(int8, symint8)
sput(int16, symint16)
sput(int32, symint32)
sput(int64, symint64)

sput(uint, symuint)
sput(uint8, symuint8)
sput(uint16, symuint16)
sput(uint64, symuint64)
sput(uint64, symuint64)

sput(float, symfloat)
sput(float32, symfloat32)
sput(float64, symfloat64)

proc get*[T : SomeNumber](mk : ModeKind, dst : var openArray[T], src : symarray[T], pe : int) =
    case mk:
    of blocking:
        get(dst, src, pe) 
    of nonblocking:
        nbget(dst, src, pe)

proc get*[T : SomeNumber](self : symarray[T], mk : ModeKind, pe : int) : openArray[T] =
    result.setLen(self.len)
    get(result, self, pe)

proc get*[T : SomeNumber](mk : ModeKind, self : symarray[T], pe : int) : openArray[T] =
    result.setLen(self.len)
    get(result, self, pe)

template sget(typa : typedesc , typb: typedesc) =
    proc get*[T : typa, F : typb](self : T, pe : int) : F =
        bindings.get(result.addr, self, pe)

    proc nbget*[T : typa, F : typb](self : T, pe : int) : F =
        bindings.nbget(result.addr, self, pe)

    proc get*[T : typa, F : typb](mk : ModeKind, src : var T, pe : int) : F =
        case mk:
        of blocking:
            bindings.get(result.addr, src, pe)
        of nonblocking:
            bindings.nbget(result.addr, src, pe)

    proc get*[T : typa, F : typb](self : T, mk : ModeKind, pe : int) : F =
        bindings.get(result.addr, self, pe)

    proc get*[T : typa, F : typb](mk : ModeKind, self : T, pe : int) : F =
        bindings.get(result.addr, self, pe)

sget(symint, int)
sget(symint8, int8)
sget(symint16, int16)
sget(symint32, int32)
sget(symint64, int64)

sget(symuint, uint)
sget(symuint8, uint8)
sget(symuint16, uint16)
sget(symuint32, uint32)
sget(symuint64, uint64)

sget(symfloat, float)
sget(symfloat32, float32)
sget(symfloat64, float64)

type ReductionKind* = enum
    minop,
    maxop,
    sumop,
    prodop

template reduceTemplate(a:typedesc) =
    proc reduce*(rk : ReductionKind, team : Team, dst : var symarray[a], src : var symarray[a] ) : int =
        case rk:
        of minop:
          bindings.min_reduce(team, dst.data, src.data, dst.len)
        of maxop:
          bindings.max_reduce(team, dst.data, src.data, dst.len)
        of sumop:
          bindings.sum_reduce(team, dst.data, src.data, dst.len)
        of prodop: 
          bindings.prod_reduce(team, dst.data, src.data, dst.len)

reduceTemplate(cint)
reduceTemplate(cshort)
reduceTemplate(clong)
reduceTemplate(cuint)
reduceTemplate(cushort)
reduceTemplate(culong)
reduceTemplate(cfloat)
reduceTemplate(cdouble)

proc min*[T](team : Team, dst : var symarray[T], src : var symarray[T]) : int =
    reduce(minop, team, dst, src)

proc max*[T](team : Team, dst : symarray[T], src : symarray[T]) : int =
    reduce(maxop, team, dst, src)

proc sum*[T](team : Team, dst : symarray[T], src : symarray[T]) : int =
    reduce(sumop, team, dst, src)

proc prod*[T](team : Team, dst : symarray[T], src : symarray[T]) : int =
    reduce(prodop, team, dst, src)

proc broadcast*[T](team : Team, dst : symarray[T], src : symarray[T], root: int) : int =
    result = bindings.broadcast(team, dst.data, src.data, dst.len, root)

proc alltoall*[T](team : Team, dst : symarray[T], src : symarray[T]) : int =
    result = bindings.alltoall(team, dst.data, src, dst.len)

proc reduce[T](vals : symarray[T], init : T, fn : proc(x:T, y:T) : T ) : T =
    result = init
    for i in 0..<vals.len:
        result = fn(result, vals[i])

proc reduce*[T, F](rk : ReductionKind, team : Team, src : var symarray[T], init : F, fn : proc(x:T, y:T):T ) : F =
    let val = src[0]
    src[0] = reduce[T](src, cast[T](init), fn)
    discard reduce(rk, team, src, src)
    result = cast[F](src[0])
    src[0] = val

proc reduce*[T, F](rk : ReductionKind, team : Team, src : var symarray[T], init : F) : F =
    case rk:
    of minop:
      proc min_reduce_impl_sos(x:T, y:T) : T =
          result = min(x, y)
      result = reduce(minop, team, src, init, min_reduce_impl_sos)
    of maxop:
      proc max_reduce_impl_sos(x:T, y:T) : T =
          result = max(x, y)
      result = reduce(maxop, team, src, init, max_reduce_impl_sos)
    of sumop:
      proc sum_reduce_impl_sos(x:T, y:T) : T =
          result = x + y
      result = reduce(sumop, team, src, init, sum_reduce_impl_sos)
    of prodop:
      proc prod_reduce_impl_sos(x:T, y:T) : T =
          result = x * y
      result = reduce(prodop, team, src, init, prod_reduce_impl_sos)

proc fence*() =
    bindings.fence()

proc quiet*() =
    bindings.quiet()

proc barrier*() =
    bindings.barrier_all()

const collapseSymChoice = not defined(nimLegacyMacrosCollapseSymChoice)

proc sosAnalyzeTree(n : NimNode, stmts: var NimNode, level = 0) =
  case n.kind
    of nnkEmpty, nnkNilLit:
      discard # same as nil node in this representation
    of nnkNone:
      assert false
    of nnkStmtList:
      for child in n:
        sosAnalyzeTree(child, stmts, level+1)
    of nnkVarSection:
      for c in n:
        # c[0] = variable name
        # c[1] = variable type
        #
        if c[1].kind != nnkEmpty:
          let varname : string = c[0].strVal
          if c[1].kind == nnkBracketExpr:
            if c[1].len != 3:
              error("***sosSymStaticArrayDecl*** Found Error -> Variable: " & varname & "'s type not symsarray")

            if c[1][0].strVal == "symsarray":
              let nelem : int = int(c[1][1].intVal)
              if nelem < 0:
                error("***sosSymStaticArrayDecl*** Found Error -> Variable: " & varname & "'s size is < 0")

              let typename : string = c[1][2].strVal
              var ctype : string
              case typename:
                of "int":
                  ctype = "int"
                of "int8":
                  ctype = "int"
                of "int16":
                  ctype = "int"
                of "int32":
                  ctype = "int"
                of "int64":
                  ctype = "int64_t"
                of "uint":
                  ctype = "unsigned int"
                of "uint8":
                  ctype = "uint8_t"
                of "uint16":
                  ctype = "uint16_t"
                of "uint32":
                  ctype = "uint32_t"
                of "uint64":
                  ctype = "uint64_t"
                of "float":
                  ctype = "float"
                of "float32":
                  ctype = "float"
                of "float64":
                  ctype = "double"
                else:
                  error("***sosSymStaticArrayDecl*** Found Error -> Variable: " & varname & "'s type not SomeNumber; type is " & typename)

              # create a 'shadow' variable that is annotated to be static
              # (placed in the underlying C program's data segment); to do
              # this, hash the variable's name, create a new variable that
              # has the name `variablenameVariableHashValueVariableName`;
              # the user's provided variable `symscalar` is an address to
              # this 'shadow' variable
              #
              let varnamehashstr : string = intToStr(hash(varname))
              let varnamehashvar : string = varname & varnamehashstr & varname
              #let codegen : string = "static " & ctype & " " & varnamehashvar & " [" & $nelem & "]"
              let codegen : string = "static $# $#" & " [" & $nelem & "]"
              let pragmaStr : string = "var " & varnamehashvar & " {.codegenDecl: \"" & codegen & " \".} : ptr " & typename
              let symfullStr : string = "var " & varname & " : symsarray[ " & $nelem & ", " & typename & " ] = ( " & $nelem & ", " & varnamehashvar & " )"

              #echo pragmaStr, '\n', symfullStr

              stmts.add( parseStmt(pragmaStr) )
              stmts.add( parseStmt(symfullStr) )
          else:
            let typename : string = c[1].strVal
            #var ctype : string 
            var nimtype : string
            case typename:
              of "symint":
                #ctype = "int"
                nimtype = "cint"
              of "symint8":
                #ctype = "int"
                nimtype = "cshort"
              of "symint16":
                #ctype = "int"
                nimtype = "cshort"
              of "symint32":
                #ctype = "int"
                nimtype = "cint"
              of "symint64":
                #ctype = "int64_t"
                nimtype = "clonglong"
              of "symuint":
                #ctype = "unsigned int"
                nimtype = "cuint"
              of "symuint8":
                #ctype = "uint8_t"
                nimtype = "cushort"
              of "symuint16":
                #ctype = "uint16_t"
                nimtype = "cushort"
              of "symuint32":
                #ctype = "uint32_t"
                nimtype = "cuint"
              of "symuint64":
                #ctype = "uint64_t"
                nimtype = "culonglong"
              of "symfloat":
                #ctype = "float"
                nimtype = "cfloat"
              of "symfloat32":
                #ctype = "float"
                nimtype = "cfloat"
              of "symfloat64":
                #ctype = "double"
                nimtype = "clongfloat"
              #else:
              #  error("***sosStatic*** Found Error -> Variable: " & varname & "'s type not SomeNumber; type is " & typename)

            if nimtype.len > 0:
              # create a 'shadow' variable that is annotated to be static
              # (placed in the underlying C program's data segment); to do
              # this, hash the variable's name, create a new variable that
              # has the name `variablenameVariableHashValueVariableName`;
              # the user's provided variable `symscalar` is an address to
              # this 'shadow' variable
              #
              let pragmaStr : string = " {.codegenDecl: \"static $# $# \" .}"
              let varnamehashstr : string = intToStr(hash(varname))
              let varnamehashvar : string = varname & varnamehashstr & varname
              let fullStr : string = "var " & varnamehashvar & pragmaStr & " : " & nimtype
              let symfullStr : string = "var " & varname & " : " & typename & " = unsafeAddr(" & varnamehashvar & ")"

              #echo fullStr, '\n', symfullStr
              stmts.add( parseStmt(fullStr) )
              stmts.add( parseStmt(symfullStr) )

    elif n.kind in {nnkOpenSymChoice, nnkClosedSymChoice} and collapseSymChoice:
      if n.len > 0:
        var allSameSymName = true
        for i in 0..<n.len:
          if n[i].kind != nnkSym or not eqIdent(n[i], n[0]):
            allSameSymName = false
            break
        if not allSameSymName:
          for j in 0 ..< n.len:
            sosAnalyzeTree(n[j], stmts, level+1)
    else:
      for j in 0 ..< n.len:
        sosAnalyzeTree(n[j], stmts, level+1)

proc sosVarAnalyze(n:NimNode) : NimNode =
  result = newStmtList() 
  sosAnalyzeTree(n, result)

macro sosVarDecl(s : untyped) : untyped = s.sosVarAnalyze

template SymmetricMain*(body : untyped) =
    sosVarDecl:
        body
    bindings.ini()
    block:
        body
    bindings.fin()
