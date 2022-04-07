#! /bin/bash

NCPU=$(cat /proc/cpuinfo | grep processor| wc -l)

#export COMPOSITE_FUNCTION=median
export COMPOSITE_FUNCTION=mean
export PRODUCT=CLFG

#date --date "1 jan 2019 273 days" -> Tue Oct  1 00:00:00 UTC 2019
#date --date "1 jan 2019 303 days" -> Thu Oct 31 00:00:00 UTC 2019
#date --date "1 jan 2019 281 days" -> Wed Oct  9 00:00:00 UTC 2019 ## Typhoon Haigis

for YEAR in 2019; do
    export YEAR
    for BUF in 4 5 6; do

	DATE_START=$(expr 281 - $BUF)
	DATE_END=$(expr 281 + $BUF)

	parallel ./getCLFG.sh {1} {2} ::: $(seq ${DATE_START} ${DATE_END}) :::: TileNum.lst

	parallel -j75% ./composite.CLFG.sh {} ${DATE_START} ${DATE_END} ${COMPOSITE_FUNCTION} :::: TileNum.lst
	#for TILE in $(cat TileNum.lst); do bash -x ./composite.CLFG.sh $TILE ${DATE_START} ${DATE_END} ${COMPOSITE_FUNCTION}; done
	
	parallel -j75% ./flagCloudPixels.sh ${DATE_START} ${DATE_END} {} {} ::: 0.01 ::: 0.35
	#./flagCloudPixels.sh ${DATE_START} ${DATE_END} 0.18 0.40

    done
done
