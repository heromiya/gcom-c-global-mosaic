#! /bin/bash

NCPU=$(cat /proc/cpuinfo | grep processor| wc -l)

#export COMPOSITE_FUNCTION=median
export COMPOSITE_FUNCTION=mean
export PRODUCT=CLFG

#date --date "1 jan 2019 273 days" -> Tue Oct  1 00:00:00 UTC 2019
#date --date "1 jan 2019 303 days" -> Thu Oct 31 00:00:00 UTC 2019

DATE_START=273
DATE_END=289
#DATE_END=303

#parallel ./getCLFG.sh {1} {2} ::: $(seq ${DATE_START} ${DATE_END}) :::: TileNum.lst
#parallel --shuf ./getCLFG.sh {1} {2} ::: $(seq ${DATE_START} ${DATE_END}) ::: 0529
#bash -x ./getCLFG.sh 273 0529

#parallel ./composite.CLFG.sh {} ${DATE_START} ${DATE_END} ${COMPOSITE_FUNCTION} :::: TileNum.lst
#bash -x ./composite.CLFG.sh 0529 ${DATE_START} ${DATE_END} ${COMPOSITE_FUNCTION}
./flagCloudPixels.sh ${DATE_START} ${DATE_END} 0.1 0.2

#parallel cloudCombine {} {} ::: $(seq 40 10 90) ::: $(seq 100 10 150)
