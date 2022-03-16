<!-- Copyright (c) 2022 Christopher Taylor                                          -->
<!--                                                                                -->
<!--   Distributed under the Boost Software License, Version 1.0. (See accompanying -->
<!--   file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)        -->
# [nim-sos - Nim Sandia OpenSHMEM](https://github.com/ct-clmsn/nim-sos)

`nim-sos` wraps the existing [SOS](https://github.com/Sandia-OpenSHMEM/SOS) OpenSHMEM library implemented by Sandia National
Laboratory. `nim-sos` provides the [Nim](https://nim-lang.org) programming language support for distributed symmetric shared
memory.

`nim-sos` provides a *symmetric sequence type*. Symmetric sequences are an extension to the existing [Nim sequence type](https://nim-lang.org/docs/system.html#seq)
that wrap symmetric memory allocations. Symmetric sequences only support values that are of [SomeNumber](https://nim-lang.org/docs/system.html#SomeNumber) types.
Symmetric sequences provide element-access, slice, iterator, and partitioning support.

This library provides a convenient mechanism for implementing OpenSHMEM programs using Nim templates and blocks.
Use of the `sosBlock` feature wraps the users code with the proper `shmem_init` and `shmem_finalize` calls.

### Developer Notes

New users are encouraged to review the OpenSHMEM specification [here](http://openshmem.org/site/Specification). Programs
implemented using `nim-sos` will require use of the [SPMD style](https://en.wikipedia.org/wiki/SPMD).

# What is a *Symmetric Sequence*?

Nim provides an array type called a 'sequence'. `nim-sos` provides a *symmetric* version of the `seq` data type. Symmetric
sequences, instantiated by processing elements (PEs[1]) running in SPMD, create a global sequence partitioned across the available
PEs. Symmetric sequences consist of globally addressable partitions. Users can `get` from and `put` into  a remote partition of
the symmetric sequence.

[1] A PE is a program process running in SPMD on a computer or set of computers. Applications running in SPMD can run in a
distributed (cluster) or a single machine setting.

Consider the Symmetric Sequence 'S' that is created in an SPMD program running on 2 PEs. 'S' spans 2 PEs, or 2 processes residing
on the same or a different machine.

        ---------------------------
        -            S            -
        -  ++++++++     ++++++++  -
        -  + PE 0 +     + PE 1 +  -
        -  +      +     +      +  -
        -  +  A   +     +  B   +  -
        -  ++++++++     ++++++++  -
        ---------------------------

'S' is composed of two partitions, 'A' and 'B'. 'A' resides in the 1st processes memory (PE 0) and 'B' resides in a 2nd processes
memory (PE 1). The process that contains partition 'A' can 'get' a copy of the values in partition 'B' using Symmetric Sequence 'S'
as the shared point of reference. The process that contains partition 'B' can 'put' values into partition 'A' using the Symmetric
Sequence 'S' as a shared point of reference. Symmetric Sequence operations are single-sided. PE 0 receives no notifications in the
event partition 'A' is modified due to a communication operation.

Users are required the define the size of each partition when creating Symmetric Sequences. Calling the constructor for `newSymSeq[int](100)`
for a 32 node program run will create a Symmetric Sequence with 32 partitions, each partition being 100 integers in type and length.
A convenience function called `partitionSizer` is provided to calculate a partition size given the global number of elements that need
to be stored. If a user needs a Symmetric Sequence stored on 32 nodes for 3200 integers, `partitionSizer` will peform the simple
calculation and return 100 integers for each partition.

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
