#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
# Package
version       = "0.0.1"
author        = "Christopher Taylor"
description   = "nim-sos a Sandia OpenSHMEM wrapper"
license       = "boost"

# Dependencies
requires "nim >= 0.18.0"

task gendoc, "Generate documentation":
  exec("nimble doc --project sos.nim --out:docs/")
