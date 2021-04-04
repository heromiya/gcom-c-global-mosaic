#! /bin/bash

export BUF=$1
export BUF02d=$(printf %02d $BUF)
export TH=100
export SIEVE=30
export CLD_MIN=30
export CLD_MAX=150

for B in {1..3}; do
    make scaled/scaled.composite.LTOA.$BUF02d.$COMPOSITE_FUNCTION.$B.vrt
done
make cloud.alpha.combined.d/RSRF.NWLRK.cloud.alpha.LTOA.20210328_$BUF02d.$CLD_MIN-$CLD_MAX.$COMPOSITE_FUNCTION.tif
