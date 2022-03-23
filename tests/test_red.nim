#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
import ../sos/sos

sosBlock:
    var a = newSymArray[int]([1,2,3,4,5])
    var b = newSymArray[int](a.len)

    # pick an op to reduce
    #
    let rmin = reduce(minop, WORLD, b, a)
    echo(rmin)

    # op can reduce
    #
    let mrmin = minop.reduce(WORLD, b, a)
    echo(mrmin)

    # op can be called
    #
    let mmrmin = min(WORLD, b, a)
    echo(mmrmin)

    # teams can invoke reduction
    #
    let rrmin = WORLD.min(b, a)
    echo(rrmin)

    # puts/gets
    #
    var c = newSeq[int](5)
    put(c, b, 1)
    c.put(b, 1)

    get(c, b, 1)
    c.get(b, 1)

    c.put(b, 1) # put c into b
    c.get(b, 1) # get c from b

    put(blocking, c, b, 1)
    get(blocking, c, b, 1)

    blocking.put(c, b, 1)
    blocking.get(c, b, 1)
