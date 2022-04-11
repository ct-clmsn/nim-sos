#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
{.deadCodeElim: on.}
{.passL: "-lrt -lpmi_simple -lsma" .}
import std/macros

{.emit: """#include<mpp/shmem-def.h>""".}

type Team* {.importc: "shmem_team_t", header: "<mpp/shmem-def.h>".} = object
type Context* {.importc: "shmem_context_t", header: "<shmem.h>".} = object
type Config* {.importc: "shmem_config_t", header: "<shmem.h>".} = object

{.emit: """extern shmem_team_t SHMEM_TEAM_WORLD; extern shmem_team_t SHMEM_TEAM_SHARED;""".}

var TEAM_WORLD* {.importc: "SHMEM_TEAM_WORLD", header: "<shmem.h>".} : Team
var TEAM_SHARED* {.importc: "SHMEM_TEAM_SHARED", header: "<shmem.h>".} : Team

proc my_pe*(team : Team) : int {.importc: "shmem_team_my_pe", header : "<shmem.h>".}
proc n_pes*(team : Team) : int {.importc: "shmem_team_n_pes", header : "<shmem.h>".}

proc translate_pe*(src_team : Team, src_pe : int, dst_team : Team) : int {.importc: "shmem_team_translate_pe", header : "<shmem.h>".}
proc split_strided*(par_team : Team, strt : int, stride : int, size : int, config : Config, config_mask : int, new_team : var Team) : int {.importc: "shmem_team_split_strided", header : "<shmem.h>".}
proc split_2d*(par_team : Team, xrng: int, xaxis_config : Config, x_mask : int, xteam : var Team, yaxis_config : Config, y_mask : int, yteam : var Team) : int {.importc: "shmem_team_split_2d", header : "<shmem.h>".}
proc destroy*(team : var Team) {.importc: "shmem_team_destroy", header : "<shmem.h>".}

proc create(ctx : var Context, options : int) : int {.importc: "shmem_ctx_create", header : "<shmem.h>".}
proc create(team : Team, ctx : var Context, options : int) : int {.importc: "shmem_ctx_create", header : "<shmem.h>".}
proc destroy(ctx : var Context) : int {.importc: "shmem_ctx_destroy", header : "<shmem.h>".}
proc get(ctx : Context, team : var Team) : int {.importc: "shmem_ctx_get_team", header : "<shmem.h>".}

proc ini*() {.importc: "shmem_init", header: "<shmem.h>".}
proc fin*() {.importc: "shmem_finalize", header: "<shmem.h>".}

proc n_pes*() : uint32 {.importc: "shmem_n_pes", header: "<shmem.h>".}
proc my_pe*() : uint32 {.importc: "shmem_my_pe", header: "<shmem.h>".}

proc put*(dst : ptr UncheckedArray[int], src : ptr openarray[int], nelems : int, pe : int) {.importc: "shmem_int_put", header: "<shmem.h>".}
proc put*(dst : ptr UncheckedArray[int32], src : ptr openarray[int32], nelems : int, pe : int) {.importc: "shmem_int_put", header: "<shmem.h>".} 
proc put*(dst : ptr UncheckedArray[int64], src : ptr openarray[int64], nelems : int, pe : int) {.importc: "shmem_int_put", header: "<shmem.h>".} 

proc put*(dst : ptr UncheckedArray[uint], src : ptr openarray[uint], nelems : int, pe : int) {.importc: "shmem_uint_put", header: "<shmem.h>".}
proc put*(dst : ptr UncheckedArray[uint32], src : ptr openarray[uint32], nelems : int, pe : int) {.importc: "shmem_uint_put", header: "<shmem.h>".}
proc put*(dst : ptr UncheckedArray[uint64], src : ptr openarray[uint64], nelems : int, pe : int) {.importc: "shmem_uint_put", header: "<shmem.h>".}

proc put*(dst : ptr UncheckedArray[float32], src : ptr openarray[float32], nelems : int, pe : int) {.importc: "shmem_float_put", header: "<shmem.h>".} 
proc put*(dst : ptr UncheckedArray[float64], src : ptr openarray[float64], nelems : int, pe : int) {.importc: "shmem_double_put", header: "<shmem.h>".} 

macro put*(dst : ptr UncheckedArray[typed], src : ptr openarray[typed], nelems : int, pe : int) =
    result = newStmtList()
    result.add( bindSym"put", dst, src )

proc get*(dst : ptr openarray[int], src : ptr UncheckedArray[int], nelems : int, pe : int) {.importc: "shmem_int_get", header: "<shmem.h>".} 
proc get*(dst : ptr openarray[int32], src : ptr UncheckedArray[int32], nelems : int, pe : int) {.importc: "shmem_int_get", header: "<shmem.h>".} 
proc get*(dst : ptr openarray[int64], src : ptr UncheckedArray[int64], nelems : int, pe : int) {.importc: "shmem_int_get", header: "<shmem.h>".} 

proc get*(dst : ptr openarray[uint], src : ptr UncheckedArray[uint], nelems : int, pe : int) {.importc: "shmem_uint_get", header: "<shmem.h>".} 
proc get*(dst : ptr openarray[uint32], src : ptr UncheckedArray[uint32], nelems : int, pe : int) {.importc: "shmem_uint_get", header: "<shmem.h>".} 
proc get*(dst : ptr openarray[uint64], src : ptr UncheckedArray[uint64], nelems : int, pe : int) {.importc: "shmem_uint_get" , header: "<shmem.h>".} 

proc get*(dst : ptr openarray[float32], src : ptr UncheckedArray[float32], nelems : int, pe : int) {.importc: "shmem_float_get", header: "<shmem.h>".} 
proc get*(dst : ptr openarray[float64], src : ptr UncheckedArray[float64], nelems : int, pe : int) {.importc: "shmem_double_get", header: "<shmem.h>".} 

macro get*(dst : ptr openarray[typed], src : ptr UncheckedArray[typed], nelems : int, pe : int) =
    result = newStmtList()
    result.add( bindSym"get", dst, src )

proc nbput*(dst : ptr UncheckedArray[int], src : ptr openarray[int], nelems : int, pe : int) {.importc: "shmem_int_put_nbi", header: "<shmem.h>".}
proc nbput*(dst : ptr UncheckedArray[int32], src : ptr openarray[int32], nelems : int, pe : int) {.importc: "shmem_int_put_nbi", header: "<shmem.h>".} 
proc nbput*(dst : ptr UncheckedArray[int64], src : ptr openarray[int64], nelems : int, pe : int) {.importc: "shmem_int_put_nbi", header: "<shmem.h>".} 

proc nbput*(dst : ptr UncheckedArray[uint], src : ptr openarray[uint], nelems : int, pe : int) {.importc: "shmem_uint_put_nbi", header: "<shmem.h>".}
proc nbput*(dst : ptr UncheckedArray[uint32], src : ptr openarray[uint32], nelems : int, pe : int) {.importc: "shmem_uint_put_nbi", header: "<shmem.h>".}
proc nbput*(dst : ptr UncheckedArray[uint64], src : ptr openarray[uint64], nelems : int, pe : int) {.importc: "shmem_uint_put_nbi", header: "<shmem.h>".}

proc nbput*(dst : ptr UncheckedArray[float32], src : ptr openarray[float32], nelems : int, pe : int) {.importc: "shmem_float_put_nbi", header: "<shmem.h>".} 
proc nbput*(dst : ptr UncheckedArray[float64], src : ptr openarray[float64], nelems : int, pe : int) {.importc: "shmem_double_put_nbi", header: "<shmem.h>".} 

macro nbput*(dst : ptr UncheckedArray[typed], src : ptr openarray[typed], nelems : int, pe : int) =
    result = newStmtList()
    result.add( bindSym"nbput", dst, src )

proc nbget*(dst : ptr openarray[int], src : ptr UncheckedArray[int], nelems : int, pe : int) {.importc: "shmem_int_get_nbi", header: "<shmem.h>".} 
proc nbget*(dst : ptr openarray[int32], src : ptr UncheckedArray[int32], nelems : int, pe : int) {.importc: "shmem_int_get_nbi", header: "<shmem.h>".} 
proc nbget*(dst : ptr openarray[int64], src : ptr UncheckedArray[int64], nelems : int, pe : int) {.importc: "shmem_int_get_nbi", header: "<shmem.h>".} 

proc nbget*(dst : ptr openarray[uint], src : ptr UncheckedArray[uint], nelems : int, pe : int) {.importc: "shmem_uint_get_nbi", header: "<shmem.h>".} 
proc nbget*(dst : ptr openarray[uint32], src : ptr UncheckedArray[uint32], nelems : int, pe : int) {.importc: "shmem_uint_get_nbi", header: "<shmem.h>".} 
proc nbget*(dst : ptr openarray[uint64], src : ptr UncheckedArray[uint64], nelems : int, pe : int) {.importc: "shmem_uint_get_nbi" , header: "<shmem.h>".} 

proc nbget*(dst : ptr openarray[float32], src : ptr UncheckedArray[float32], nelems : int, pe : int) {.importc: "shmem_float_get_nbi", header: "<shmem.h>".} 
proc nbget*(dst : ptr openarray[float64], src : ptr UncheckedArray[float64], nelems : int, pe : int) {.importc: "shmem_double_get_nbi", header: "<shmem.h>".} 

macro nbget*(dst : ptr openarray[typed], src : ptr UncheckedArray[typed], nelems : int, pe : int) =
    result = newStmtList()
    result.add( bindSym"nbget", dst, src )

proc sync_all*() : int {.importc: "shmem_sync_all", header: "<shmem.h>".}
proc barrier_all*() {.importc: "shmem_barrier_all", header: "<shmem.h>".}

proc min_reduce*(team : Team, dst : ptr UncheckedArray[int], src : ptr UncheckedArray[int],  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr UncheckedArray[int32], src : ptr UncheckedArray[int32],  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr UncheckedArray[int64], src : ptr UncheckedArray[int64],  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}

proc min_reduce*(team : Team, dst : ptr UncheckedArray[uint], src : ptr UncheckedArray[uint],  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr UncheckedArray[uint32], src : ptr UncheckedArray[uint32],  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr UncheckedArray[uint64], src : ptr UncheckedArray[uint64],  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}

proc min_reduce*(team : Team, dst : ptr UncheckedArray[float32], src : ptr UncheckedArray[float32],  nelems : int) : int {.importc: "shmem_float_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr UncheckedArray[float64], src : ptr UncheckedArray[float64],  nelems : int) : int {.importc: "shmem_double_min_reduce", header: "<shmem.h>".}

macro min_reduce*(team : Team, dst : ptr UncheckedArray[typed], src : ptr UncheckedArray[typed],  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"min_reduce", team, src, dst, nelems)

proc min_reduce*(team : Team, dst : ptr int, src : ptr int,  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr int32, src : ptr int32,  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr int64, src : ptr int64,  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}

proc min_reduce*(team : Team, dst : ptr uint, src : ptr uint,  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr uint32, src : ptr uint32,  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr uint64, src : ptr uint64,  nelems : int) : int {.importc: "shmem_int_min_reduce", header: "<shmem.h>".}

proc min_reduce*(team : Team, dst : ptr float32, src : ptr float32,  nelems : int) : int {.importc: "shmem_float_min_reduce", header: "<shmem.h>".}
proc min_reduce*(team : Team, dst : ptr float64, src : ptr float64,  nelems : int) : int {.importc: "shmem_double_min_reduce", header: "<shmem.h>".}

macro min_reduce*(team : Team, dst : ptr typed, src : ptr typed,  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"min_reduce", team, src, dst, nelems)

proc max_reduce*(team : Team, dst : ptr UncheckedArray[int], src : ptr UncheckedArray[int],  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr UncheckedArray[int32], src : ptr UncheckedArray[int32],  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr UncheckedArray[int64], src : ptr UncheckedArray[int64],  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}

proc max_reduce*(team : Team, dst : ptr UncheckedArray[uint], src : ptr UncheckedArray[uint],  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr UncheckedArray[uint32], src : ptr UncheckedArray[uint32],  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr UncheckedArray[uint64], src : ptr UncheckedArray[uint64],  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}

proc max_reduce*(team : Team, dst : ptr UncheckedArray[float32], src : ptr UncheckedArray[float32],  nelems : int) : int {.importc: "shmem_float_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr UncheckedArray[float64], src : ptr UncheckedArray[float64],  nelems : int) : int {.importc: "shmem_double_max_reduce", header: "<shmem.h>".}

macro max_reduce*(team : Team, dst : ptr UncheckedArray[typed], src : ptr UncheckedArray[typed],  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"max_reduce", team, src, dst, nelems)

proc max_reduce*(team : Team, dst : ptr int, src : ptr int,  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr int32, src : ptr int32,  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr int64, src : ptr int64,  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}

proc max_reduce*(team : Team, dst : ptr uint, src : ptr uint,  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr uint32, src : ptr uint32,  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr uint64, src : ptr uint64,  nelems : int) : int {.importc: "shmem_int_max_reduce", header: "<shmem.h>".}

proc max_reduce*(team : Team, dst : ptr float32, src : ptr float32,  nelems : int) : int {.importc: "shmem_float_max_reduce", header: "<shmem.h>".}
proc max_reduce*(team : Team, dst : ptr float64, src : ptr float64,  nelems : int) : int {.importc: "shmem_double_max_reduce", header: "<shmem.h>".}

macro max_reduce*(team : Team, dst : ptr typed, src : ptr typed,  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"max_reduce", team, src, dst, nelems)

proc sum_reduce*(team : Team, dst : ptr UncheckedArray[int], src : ptr UncheckedArray[int],  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr UncheckedArray[int32], src : ptr UncheckedArray[int32],  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr UncheckedArray[int64], src : ptr UncheckedArray[int64],  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}

proc sum_reduce*(team : Team, dst : ptr UncheckedArray[uint], src : ptr UncheckedArray[uint],  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr UncheckedArray[uint32], src : ptr UncheckedArray[uint32],  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr UncheckedArray[uint64], src : ptr UncheckedArray[uint64],  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}

proc sum_reduce*(team : Team, dst : ptr UncheckedArray[float32], src : ptr UncheckedArray[float32],  nelems : int) : int {.importc: "shmem_float_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr UncheckedArray[float64], src : ptr UncheckedArray[float64],  nelems : int) : int {.importc: "shmem_double_sum_reduce", header: "<shmem.h>".}

macro sum_reduce*(team : Team, dst : ptr UncheckedArray[typed], src : ptr UncheckedArray[typed],  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"sum_reduce", team, src, dst, nelems)

proc sum_reduce*(team : Team, dst : ptr int, src : ptr int,  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr int32, src : ptr int32,  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr int64, src : ptr int64,  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}

proc sum_reduce*(team : Team, dst : ptr uint, src : ptr uint,  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr uint32, src : ptr uint32,  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr uint64, src : ptr uint64,  nelems : int) : int {.importc: "shmem_int_sum_reduce", header: "<shmem.h>".}

proc sum_reduce*(team : Team, dst : ptr float32, src : ptr float32,  nelems : int) : int {.importc: "shmem_float_sum_reduce", header: "<shmem.h>".}
proc sum_reduce*(team : Team, dst : ptr float64, src : ptr float64,  nelems : int) : int {.importc: "shmem_double_sum_reduce", header: "<shmem.h>".}

macro sum_reduce*(team : Team, dst : ptr typed, src : ptr typed,  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"sum_reduce", team, src, dst, nelems)

proc prod_reduce*(team : Team, dst : ptr UncheckedArray[int], src : ptr UncheckedArray[int],  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr UncheckedArray[int32], src : ptr UncheckedArray[int32],  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr UncheckedArray[int64], src : ptr UncheckedArray[int64],  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}

proc prod_reduce*(team : Team, dst : ptr UncheckedArray[uint], src : ptr UncheckedArray[uint],  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr UncheckedArray[uint32], src : ptr UncheckedArray[uint32],  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr UncheckedArray[uint64], src : ptr UncheckedArray[uint64],  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}

proc prod_reduce*(team : Team, dst : ptr UncheckedArray[float32], src : ptr UncheckedArray[float32],  nelems : int) : int {.importc: "shmem_float_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr UncheckedArray[float64], src : ptr UncheckedArray[float64],  nelems : int) : int {.importc: "shmem_double_prod_reduce", header: "<shmem.h>".}

macro prod_reduce*(team : Team, dst : ptr UncheckedArray[typed], src : ptr UncheckedArray[typed],  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"prod_reduce", team, src, dst, nelems)

proc prod_reduce*(team : Team, dst : ptr int, src : ptr int,  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr int32, src : ptr int32,  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr int64, src : ptr int64,  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}

proc prod_reduce*(team : Team, dst : ptr uint, src : ptr uint,  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr uint32, src : ptr uint32,  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr uint64, src : ptr uint64,  nelems : int) : int {.importc: "shmem_int_prod_reduce", header: "<shmem.h>".}

proc prod_reduce*(team : Team, dst : ptr float32, src : ptr float32,  nelems : int) : int {.importc: "shmem_float_prod_reduce", header: "<shmem.h>".}
proc prod_reduce*(team : Team, dst : ptr float64, src : ptr float64,  nelems : int) : int {.importc: "shmem_double_prod_reduce", header: "<shmem.h>".}

macro prod_reduce*(team : Team, dst : ptr typed, src : ptr typed,  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"prod_reduce", team, src, dst, nelems)

proc alltoall*(team : Team, dst : ptr UncheckedArray[int], src : ptr openarray[int],  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr UncheckedArray[int32], src : ptr openarray[int32],  nelems : int) : int {.importc: "shmem_int_alltall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr UncheckedArray[int64], src : ptr openarray[int64],  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}

proc alltoall*(team : Team, dst : ptr UncheckedArray[uint], src : ptr openarray[uint],  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr UncheckedArray[uint32], src : ptr openarray[uint32],  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr UncheckedArray[uint64], src : ptr openarray[uint64],  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}

proc alltoall*(team : Team, dst : ptr UncheckedArray[float32], src : ptr openarray[float32],  nelems : int) : int {.importc: "shmem_float_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr UncheckedArray[float64], src : ptr openarray[float64],  nelems : int) : int {.importc: "shmem_double_alltoall", header: "<shmem.h>".}

macro alltoall*(team : Team, dst : ptr UncheckedArray[typed], src : ptr openarray[typed],  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"alltoall", team, src, dst, nelems)

proc alltoall*(team : Team, dst : ptr int, src : ptr int,  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr int32, src : ptr int32,  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr int64, src : ptr int64,  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}

proc alltoall*(team : Team, dst : ptr uint, src : ptr uint,  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr uint32, src : ptr uint32,  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr uint64, src : ptr uint64,  nelems : int) : int {.importc: "shmem_int_alltoall", header: "<shmem.h>".}

proc alltoall*(team : Team, dst : ptr float32, src : ptr float32,  nelems : int) : int {.importc: "shmem_float_alltoall", header: "<shmem.h>".}
proc alltoall*(team : Team, dst : ptr float64, src : ptr float64,  nelems : int) : int {.importc: "shmem_double_alltoall", header: "<shmem.h>".}

macro alltoall*(team : Team, dst : ptr typed, src : ptr typed,  nelems : int) : int =
    result = newStmtList()
    result.add( bindSym"alltoall", team, src, dst, nelems)

proc broadcast*(team : Team, dst : ptr UncheckedArray[int], src : ptr openarray[int],  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr UncheckedArray[int32], src : ptr openarray[int32],  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr UncheckedArray[int64], src : ptr openarray[int64],  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}

proc broadcast*(team : Team, dst : ptr UncheckedArray[uint], src : ptr openarray[uint],  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr UncheckedArray[uint32], src : ptr openarray[uint32],  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr UncheckedArray[uint64], src : ptr openarray[uint64],  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}

proc broadcast*(team : Team, dst : ptr UncheckedArray[float32], src : ptr openarray[float32],  nelems : int, root:int) : int {.importc: "shmem_float_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr UncheckedArray[float64], src : ptr openarray[float64],  nelems : int, root:int) : int {.importc: "shmem_double_broadcast", header: "<shmem.h>".}

macro broadcast*(team : Team, dst : ptr UncheckedArray[typed], src : ptr openarray[typed],  nelems : int, root:int) : int =
    result = newStmtList()
    result.add( bindSym"broadcast", team, src, dst, nelems, root)

proc broadcast*(team : Team, dst : ptr int, src : ptr int,  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr int32, src : ptr int32,  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr int64, src : ptr int64,  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}

proc broadcast*(team : Team, dst : ptr uint, src : ptr uint,  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr uint32, src : ptr uint32,  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr uint64, src : ptr uint64,  nelems : int, root:int) : int {.importc: "shmem_int_broadcast", header: "<shmem.h>".}

proc broadcast*(team : Team, dst : ptr float32, src : ptr float32,  nelems : int, root:int) : int {.importc: "shmem_float_broadcast", header: "<shmem.h>".}
proc broadcast*(team : Team, dst : ptr float64, src : ptr float64,  nelems : int, root:int) : int {.importc: "shmem_double_broadcast", header: "<shmem.h>".}

macro broadcast*(team : Team, dst : ptr typed, src : ptr typed,  nelems : int, root:int) : int =
    result = newStmtList()
    result.add( bindSym"broadcast", team, src, dst, nelems, root)

proc alloc*[T : SomeNumber]( nelems : int) : ptr UncheckedArray[T] {.importc: "shmem_malloc", header: "<shmem.h>".}
proc free*[T : SomeNumber](arr : ptr UncheckedArray[T]) {.importc: "shmem_free", header: "<shmem.h>".}

proc fence*() {.importc: "shmem_fence", header: "<shmem.h>".}
proc quiet*() {.importc: "shmem_quiet", header: "<shmem.h>".}
