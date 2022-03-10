#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
LIBDIR=
INCDIR=

ifeq ($(LIBDIR),)
    $(error LIBDIR is not set)
endif

ifeq ($(INCDIR),)
    $(error INCDIR is not set)
endif

LIBS=-lpthread -lpmi_simple -lsma
CFLAGS=$(LIBS)

all:
	nim c --clibdir:$(LIBDIR) -d:danger -d:globalSymbols --cincludes:$(INCDIR) --passC:"$(CFLAGS)" --passL:"$(LIBS)" tests/test_initfin.nim
	nim c --clibdir:$(LIBDIR) -d:danger -d:globalSymbols --cincludes:$(INCDIR) --passC:"$(CFLAGS)" --passL:"$(LIBS)" tests/test_pe.nim
	nim c --clibdir:$(LIBDIR) -d:danger -d:globalSymbols --cincludes:$(INCDIR) --passC:"$(CFLAGS)" --passL:"$(LIBS)" tests/test_red.nim
	mv tests/test_initfin .
	mv tests/test_pe .
	mv tests/test_red .

clean:
	rm test_initfin
	rm test_pe
	rm test_red
