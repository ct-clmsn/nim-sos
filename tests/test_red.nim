#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
import ../sos/sos
import ../sos/bindings
import std/macros

SymmetricMain:
   let pe = sos.my_pe()
   var apple : symint
   var orange : symsarray[2, int]
   orange[0] = 1

   var a : symarrayint = newSymArray[int]([1,2,3,4,5])
   var b : symarrayint = newSymArray[int](a.len)
   var c : symarrayint = newSymArrayInt([1,1,1,1,1])
   var e : symarrayint = newSymArray[int]([1,1,1,1,1])

   var f = newSymArrayInt([1,1,1,1,1])
   var ff = newSymArrayDouble([1.0,1.0,1.0,1.0,1.0])

   var d = bindings.alloc[cint](sizeof(int)*5)
   for i in 0..<5:
       (d+i)[] = 1

   for i in 0..<5:
      echo("value\t", pe, '\t', i, '\t', (d+i)[])
   echo('\n')

   # pick an op to reduce
   #
   let rmin = bindings.sum_reduce(WORLD, d, d, 5) 
   #let rmin = reduce(sumop, WORLD, c, c)
   echo(pe, ' ', rmin)
   for i in 0..<5:
      echo("sum d value\t", pe, '\t', i, '\t', (d+i)[])
   echo('\n')

   let cmin : int = reduce(sumop, WORLD, e, c)
   echo(pe, ' ', cmin)
   for i in 0..<5:
      echo("sum c value\t", pe, '\t', i, '\t', c[i])

   let emin : int = reduce(sumop, WORLD, e, e)
   echo(pe, ' ', emin)
   for i in 0..<5:
      echo("sum e value\t", pe, '\t', i, '\t', e[i])

   #let fmin : int = reduce(sumop, WORLD, f, f)
   #echo(pe, ' ', fmin)
   #for i in 0..<5:
   #   echo("sum f value\t", pe, '\t', i, '\t', e[i])

   #let ffmin : float64 = reduce(sumop, WORLD, ff, ff)
   #echo(pe, ' ', ffmin)
   #for i in 0..<5:
   #   echo("sum f value\t", pe, '\t', i, '\t', ff[i])
   var fs : float64 = reduce(sumop, WORLD, ff, 0.0)
   echo("sumred\t", ' ', fs)
   fs = reduce(prodop, WORLD, ff, 1.0)
   echo("prodred\t", ' ', fs)
   fs = reduce(minop, WORLD, ff, 10.0)
   echo("minred\t", ' ', fs)
   fs = reduce(maxop, WORLD, ff, 0.0)
   echo("maxred\t", ' ', fs)



#[
   # op can reduce
   #
   let mrmin = minop.reduce(WORLD, b, a)
   echo(pe, ' ', mrmin)
   for i in 0..<5:
      echo("min value 0\t", a[i])

   # op can be called
   #
   let mmrmin = min(WORLD, b, a)
   echo(pe, ' ', mmrmin)
   for i in 0..<5:
      echo("sum value 0\t", a[i])


   # teams can invoke reduction
   #
   let rrmin = WORLD.min(b, a)
   echo(pe, ' ', rrmin)
   for i in 0..<5:
      echo("sum value 0\t", a[i])

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
]#
