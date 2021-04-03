#! /bin/bash

export BUF=$1

export TH=100
export SIEVE=30
export CLD_MIN=50
export CLD_MAX=120

for B in {1..3}; do
    make scaled/scaled.composite.LTOA.$BUF.$COMPOSITE_FUNCTION.$B.vrt
done
make cloud.alpha.combined.d/RSRF.NWLRK.cloud.alpha.LTOA.20210328_$BUF.$CLD_MIN-$CLD_MAX.$COMPOSITE_FUNCTION.tif
