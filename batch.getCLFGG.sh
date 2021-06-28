#! /bin/bash

NCPU=$(cat /proc/cpuinfo | grep processor| wc -l)

#export COMPOSITE_FUNCTION=median
export COMPOSITE_FUNCTION=mean
export PRODUCT=CLFG

#date --date "1 jan 2019 273 days" -> Tue Oct  1 00:00:00 UTC 2019
#date --date "1 jan 2019 303 days" -> Thu Oct 31 00:00:00 UTC 2019
#date --date "1 jan 2019 281 days" -> Wed Oct  9 00:00:00 UTC 2019 ## Typhoon Haigis

for BUF in 22; do

    DATE_START=$(expr 281 - $BUF)
    DATE_END=$(expr 281 + $BUF)

    #parallel ./getCLFG.sh {1} {2} ::: $(seq ${DATE_START} ${DATE_END}) :::: TileNum.lst

    #parallel ./composite.CLFG.sh {} ${DATE_START} ${DATE_END} ${COMPOSITE_FUNCTION} :::: TileNum.lst
    ./flagCloudPixels.sh ${DATE_START} ${DATE_END} 0.15 0.38

done
