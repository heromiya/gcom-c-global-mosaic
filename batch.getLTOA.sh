#! /bin/bash

#export COMPOSITE_FUNCTION=median
export COMPOSITE_FUNCTION=q90


parallel ./getLTOA.sh {} :::: TileNum.lst
#for TILE in $(cat TileNum.lst); do ./getLTOA.sh $TILE; done

for BUF in 7 8; do #3 5 7 9
    export BUF
    parallel ./composite.LTOA.sh {} $BUF ${COMPOSITE_FUNCTION} :::: TileNum.lst
    ./flagCloudPixels.sh $BUF
done
