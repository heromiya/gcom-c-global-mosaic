#! /bin/bash

export TH=100
export SIEVE=30
export CLD_MIN=100
export CLD_MAX=110
for BUF in 04 05; do

    export BUF
    #make RSRF.NWLRK.cloud.LTOA.20210328_$BUF.$TH.sieve$SIEVE.tif
    #make alpha.cloud.LTOA.20210328_$BUF.$TH.sieve$SIEVE.vrt
    #make cloud.alpha.LTOA.$BUF.vrt
    #make cloud.alpha.LTOA.$BUF.$CLD_MIN-$CLD_MAX.colorinterpret.tif
    for B in {1..3}; do
	make scaled/scaled.composite.LTOA.$BUF.$B.vrt
    done
    
    make RSRF.NWLRK.cloud.alpha.LTOA.20210328_$BUF.$CLD_MIN-$CLD_MAX.tif
    #gdalbuildvrt -separate cloud.LTOA.20210328_${BUF}.$TH.vrt cloud.LTOA.20210328_${BUF}.$TH.1.tif cloud.LTOA.20210328_${BUF}.$TH.2.tif cloud.LTOA.20210328_${BUF}.$TH.3.tif
done
