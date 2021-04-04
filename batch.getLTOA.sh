#! /bin/bash

NCPU=$(cat /proc/cpuinfo | grep processor| wc -l)

#export COMPOSITE_FUNCTION=median
export COMPOSITE_FUNCTION=q90

#date --date "1 jan 2019 273 days" -> Tue Oct  1 00:00:00 UTC 2019
#date --date "1 jan 2019 303 days" -> Thu Oct 31 00:00:00 UTC 2019

DATE_START=273
DATE_END=303

parallel --shuf ./getLTOA.sh {1} {2} ::: $(seq ${DATE_START} ${DATE_END}) :::: TileNum.lst


#for BUF in 7 8; 
parallel ./composite.LTOA.sh {} ${DATE_START} ${DATE_END} ${COMPOSITE_FUNCTION} :::: TileNum.lst
./flagCloudPixels.sh ${DATE_START} ${DATE_END}
#done
