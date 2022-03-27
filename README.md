<!-- Copyright (c) 2022 Christopher Taylor                                          -->
<!--                                                                                -->
<!--   Distributed under the Boost Software License, Version 1.0. (See accompanying -->
<!--   file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)        -->
# [nim-sos - Nim Sandia OpenSHMEM](https://github.com/ct-clmsn/nim-sos)

`nim-sos` wraps the existing [SOS](https://github.com/Sandia-OpenSHMEM/SOS) OpenSHMEM library implemented by Sandia National Laboratory. `nim-sos` provides the [Nim](https://nim-lang.org) programming language support for distributed symmetric shared memory.

`nim-sos` provides a *symmetric array type* and a *symmetric scalar type*.

Symmetric arrays are an extension to the existing [Nim array](https://nim-lang.org/docs/manual.html#types-array-and-sequence-types) that wrap distributed symmetric memory allocations. Symmetric arrays only support values that are of [SomeNumber](https://nim-lang.org/docs/system.html#SomeNumber) types. Symmetric arrays provide element-access, slice, iterator, and partitioning support. Symmetric arrays cannot be appended to; 'add' or 'append' functionality breaks the symmetry property.

Symmetric arrays can be instantiated either at compile-time or at runtime. Compile-time (static) symmetric arrays are called `symmetric indexed arrays`. Runtime (dynamic) symmetric arrays are called `symmetric arrays`. The naming convention is used to differentiate the memory allocation used to instatiate the array. To create a compile-time symmetric array, utilize the following type `symindexarray[A, B]` where `A` is an integer value denoting the size of the array to create at compile time and `B` is of `SomeNumber` type. Creation of the compile-time array should be done in the `sosSymIndexArrayDecl` code block as follows:

```
sosSymIndexArrayDecl:
   var a : symindexarray[100, int]
   var b : symindexarray[500, float64]
```

The `sosSymIndexArrayDecl` block above creates 2 arrays at compile time. The array `a` is of type `int` and is 100 elements. The array `b` is of type `float64` and is 500 elements.

Arrays declared with the `symarray[T:SomeNumber]` type are created at runtime. Users can dynamically or statically size the array with an invocation of the `newSymArray` constructors. `symarray[T:SomeNumber]` should be created inside the scope of an `sosBlock` block.

```
sosBlock:
    var a = newSymArray[int]([1,2,3,4,5])
    var b = newSymArray[int](a.len)
```

The `sosBlock` block above creates 2 arrays at compile time. The array `a` is of type `int` and is 5 elements with values (1,2,3,4,5). The array `b` is of type `int` and is 5 elements of uninitialized values.

Symmetric scalar values are declared using the following types within the `sosSymmetricScalars` block. The `sosSymmetricScalars` block is used to exercise symmetric scalar support.

* `symint`, `symint8`, `symint16`, `symint32`, `symint64`
* `symuint`, `symuint8`, `symuint16`, `symuint32`, `symuint64`
* `symfloat`, `symfloat32`, `symfloat64`

This library provides `sosSymmetricScalars`, a [Nim macro](https://nim-lang.org/docs/macros.html) that allows Nim scalars of [SomeNumber](https://nim-lang.org/docs/system.html#SomeNumber) types to be exposed to the global address space. Users should define `sosSymmetricScalars` prior to utilizing `sosBlock`. An example regarding how to use the `sosSymmetricScalars` block is provided below:

```
sosSymmetricScalars:
   var a : symint
   var b : symfloat
   var
      cee : symint
      d : symfloat
```

*Symmetric scalars will not work if defined outside the `sosSymmetricScalar` block!*

Symmetric scalars do not support the following operators `+`, `-`, `*`, `=`. Procedures have been implemented to provide support for these operators. All Symmetric scalars have the following methods:

* `add` : add (sum, `+`)
* `sub` : subtract (difference, `-`)
* `mul` : multiply (`*`)
* `sto` : store into the local value (`=`); similar to [atomics](https://nim-lang.org/docs/atomics.html)
* `read` : get the local value; similar to [atomics](https://nim-lang.org/docs/atomics.html)

Symmetric scalar integers have the following additional operators:

* `div` : integer divide
* `mod` : integer modulo

Symmetric scalar floats have the following additional operator:

* `div` : integer divide
* `/` : floating point divide

This library provides a convenient mechanism for implementing OpenSHMEM programs using Nim templates and blocks. Use of the `sosBlock` feature wraps the users code with the proper `shmem_init` and `shmem_finalize` calls. An example is provided below.

```
sosBlock:
    var a = newSymArray[int]([1,2,3,4,5])
    var b = newSymArray[int](a.len)

    # pick an op to reduce
    #
    let rmin = reduce(minop, WORLD, b, a)
    echo(rmin)
```

### Developer Notes

New users are encouraged to review the OpenSHMEM specification [here](http://openshmem.org/site/Specification). Programs
implemented using `nim-sos` will require use of the [SPMD style](https://en.wikipedia.org/wiki/SPMD).

*Symmetric scalars will not work if defined outside the `sosSymmetricScalar` block!*

# What is the *Symmetric Array*?

`nim-sos` provides a *symmetric* version of `array` data types in the tradition of [Fortran Coarrays](https://en.wikipedia.org/wiki/Coarray_Fortran). Symmetric arrays, instantiated by processing elements (PEs[1]) running in SPMD, create a global sequence partitioned across the available PEs. Symmetric arrays consist of globally addressable partitions. Users can `get` from and `put` into a remote partition of the symmetric array.

[1] A PE is a program process running in SPMD on a computer or set of computers. Applications running in SPMD can run in a distributed (cluster) or a single machine setting.

Consider the Symmetric array `S` that is created in an SPMD program running on 2 PEs. `S` spans 2 PEs, or 2 processes residing on the same or a different machine.

```
        ---------------------------
        -            S            -
        -  ++++++++     ++++++++  -
        -  + PE 0 +     + PE 1 +  -
        -  +      +     +      +  -
        -  +  A   +     +  B   +  -
        -  ++++++++     ++++++++  -
        ---------------------------
```

`S` is composed of two partitions, `A` and `B`. `A` resides in the 1st processes memory (PE 0) and `B` resides in a 2nd processes memory (PE 1). The process that contains partition `A` can 'get' a copy of the values in partition `B` using Symmetric array `S` as the shared point of reference. The process that contains partition `B` can 'put' values into partition `A` using the Symmetric array `S` as a shared point of reference. Symmetric array operations are single-sided. PE 0 receives no notifications in the event partition `A` is modified due to a communication operation.

Users are required to define the size of each partition when creating Symmetric array. Calling the constructor `newSymArray[int](100)` for a 32 node program run will create a Symmetric array with 32 partitions, each partition being 100 integers in type and length. A convenience function called `partitioner` is provided to calculate a partition size given the global number of elements that need to be stored. If a user needs a Symmetric array stored on 32 nodes for 3200 integers, `partitioner` will perform the simple calculation and return 100 integers for each partition.

# What is the *Symmetric Scalar*?

Similar to the symmetric array, except for scalar values.

```
        ---------------------------
        -            S            -
        -  ++++++++     ++++++++  -
        -  + PE 0 +     + PE 1 +  -
        -  +      +     +      +  -
        -  +  A   +     +  B   +  -
        -  ++++++++     ++++++++  -
        ---------------------------
```

The scalar value `S` is partitioned across 2 PEs. PE 0 has a scalar value `A`. PE 1 has a scalar value `B`. PE 0 can access `B` on PE 1 using the `S` scalar as a point of reference. PE 1 can access `A` on PE 0 using the `S` scalar as a point of reference.

One more thing...*Symmetric scalars will not work if defined outside the `sosSymmetricScalar` block!*

### Install

Download and install [SOS](https://github.com/Sandia-OpenSHMEM/SOS)
```
$ ./configure --prefix=<PATH_TO_INSTALL_DIR> --enable-pmi-simple --disable-threads --disable-openmp --with-oshrun-launcher

$ make && make install

$ export LD_LIBRARY_PATH=<PATH_TO_INSTALL_DIR>/lib:$LD_LIBRARY_PATH
```

Modify `makefile` to point `LIBDIR` and `INCDIR` to the
path set in `<PATH_TO_INSTALL_DIR>`. Use the makefile to
see if your setup compiles.
```
make
```

Use the nimble tool to install `sos`
```
nimble install sos
```

Generate documentation from source
```
nimble doc sos
```

### Running Programs

```
oshrun -n 2 -ppn 1 -hosts compute1,compute2
```

This library is designed to be run on an HPC system that manages jobs using the following workload managers: [Slurm](https://slurm.schedmd.com), PBS, etc.

### Examples

The directory 'tests/' provides several examples regarding how to utilize this library.

### Licenses

* Boost Version 1.0 (2022-)

### Date

09 March 2022

### Author

Christopher Taylor

### Special Thanks

* The OpenSHMEM developers
* Sandia National Labs/US Department of Energy
* The Nim community and user/developer forum

### Dependencies

* [nim 1.6.4](https://nim-lang.org)
* [Sandia OpenSHMEM](https://github.com/pnnl/rofi)
