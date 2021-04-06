#! /bin/bash

export DATE_START=$1
export DATE_END=$2
export DATE_START03d=$(printf %03d $DATE_START)
export DATE_END03d=$(printf %03d $DATE_END)
export VER=20210406_${DATE_START03d}-${DATE_END03d}

function cloudCombine() {
    export CLD_MIN=$1
    export CLD_MIN03d=$(printf %03d $CLD_MIN)
    export CLD_MAX=$2
    export CLD_MAX03d=$(printf %03d $CLD_MAX)

    for B in {1..3}; do
	make scaled/scaled.composite.$PRODUCT.$VER.$COMPOSITE_FUNCTION.$B.vrt
    done
    make cloud.alpha.combined.d/RSRF.NWLRK.cloud.alpha.$PRODUCT.$VER.$CLD_MIN03d-$CLD_MAX03d.$COMPOSITE_FUNCTION.tif
}
export -f cloudCombine

parallel cloudCombine {} {} ::: $(seq 40 10 90) ::: $(seq 100 10 150)
