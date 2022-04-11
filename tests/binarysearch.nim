#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
import ../sos/sos

SymmetricMain:

   let count : int = 10
   var keys : symindexarray[10, int]

   proc binsearch(key:int) : int =
      result = -1
      var lo : int
      var md : int
      var hi : int
      var val : int
      lo = 0
      hi = int(npes()) * count
      var arr : array[10, int]
      while lo < hi:
         md = lo + (hi-lo) div 2
         md = md mod count
         arr.get(keys, md div count)
         val = arr[md]
         if val == key:
             result = md
         elif val < key:
             lo = md
         else:
             hi = md

   var errors : int
   errors = 0

   for i in 0..<count:
      keys.data[i] = count * int(my_pe()) + i

   barrier()

   let n = count * int(n_pes())
   for i in 0..<n:
      var j : int = binsearch(i)
      if j != i:
         errors += 1 
