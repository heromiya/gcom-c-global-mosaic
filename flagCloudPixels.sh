#! /bin/bash

export DATE_START=$1
export DATE_END=$2
export DATE_START03d=$(printf %03d $DATE_START)
export DATE_END03d=$(printf %03d $DATE_END)
export VER=20210406_${DATE_START03d}-${DATE_END03d}

#function cloudCombine() {
export CLD_MIN=$3

export WORKDIR=$(mktemp -d)

if [ "$(echo "$CLD_MIN < 1" | bc)" -eq 1 ]; then
    export CLD_MIN03d=$(printf %03d $(perl -e "print(int($CLD_MIN * 100))"))
else
    export CLD_MIN03d=$(printf %03d $CLD_MIN)
fi

export CLD_MAX=$4

if [ "$(echo "$CLD_MAX < 1" | bc)" -eq 1 ]; then
    export CLD_MAX03d=$(printf %03d $(perl -e "print(int($CLD_MAX * 100))"))
else
    export CLD_MAX03d=$(printf %03d $CLD_MAX)
fi

for B in {1..3}; do
    make -s scaled/scaled.composite.$PRODUCT.$VER.$COMPOSITE_FUNCTION.$B.vrt
done
make cloud.alpha.combined.d/RSRF.NWLRK.cloud.alpha.$PRODUCT.$VER.$CLD_MIN03d-$CLD_MAX03d.$COMPOSITE_FUNCTION.tif

#export -f cloudCombine
