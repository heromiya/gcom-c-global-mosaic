#! /bin/bash

export TILE=$1
export BUF=$2
export BUF02d=$(printf %02d $BUF)
export COMPOSITE_FUNCTION=$3
export VER=20210328_$BUF02d
export RES=2000
export VRTDIR=VRT/LTOA/$RES/$BUF02d
mkdir -p $VRTDIR

export OUTFILE=composite/LTOA/$RES/$VER/composite.$RES.$TILE.$VER.$COMPOSITE_FUNCTION.tif
mkdir -p $(dirname $OUTFILE)

for B in VN04 VN06 VN07 ; do
    export B
    export INPUT_FILES=$(find $PWD/GCOM-C-LTOA/$RES/$TILE/ -type f -regex ".*201910.*T$TILE.*LTOAK.*.$B.2000.tif" | grep $(for BUF in $(eval echo {${BUF}..1}); do printf "10%02d\|" $(expr 9 - $BUF); done)"1009\|"$(for BUF in $(eval echo {1..${BUF}}); do printf "10%02d\|" $(expr 9 + $BUF); done | sed 's/\\|$//g;') | sort | awk 'BEGIN{ORS=" "}{print}')
    make $VRTDIR/$TILE.$B.vrt
done

make composite/LTOA/2000/20210328_$BUF02d/composite.2000.$TILE.20210328_$BUF02d.$COMPOSITE_FUNCTION.tif
