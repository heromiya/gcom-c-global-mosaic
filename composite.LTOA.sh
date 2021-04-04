#! /bin/bash

export TILE=$1
#export BUF=$2
#export BUF02d=$(printf %02d $BUF)

export DATE_START=$2
export DATE_END=$3
export DATE_START03d=$(printf %03d $DATE_START)
export DATE_END03d=$(printf %03d $DATE_END)

export COMPOSITE_FUNCTION=$4

export VER=20210328_${DATE_START03d}-${DATE_END03d}
export RES=2000
export VRTDIR=VRT/LTOA/$RES/${DATE_START03d}-${DATE_END03d}
mkdir -p $VRTDIR

export OUTFILE=composite/LTOA/$RES/$VER/composite.$RES.$TILE.$VER.$COMPOSITE_FUNCTION.tif
mkdir -p $(dirname $OUTFILE)

for B in VN04 VN06 VN07 ; do
    export B
    INPUT_DAYS=$(for D in $(eval echo {${DATE_START}..${DATE_END}}); do printf "%s\|" $(date --date "1 Jan 2019 $D days" +%m%d); done | sed 's/\\|$//g;')    
    export INPUT_FILES=$(find $PWD/GCOM-C-LTOA/$RES/$TILE/ -type f -regex ".*201910.*T$TILE.*LTOAK.*.$B.2000.tif" | grep $INPUT_DAYS | sort | awk 'BEGIN{ORS=" "}{print}')
    
    make $VRTDIR/$TILE.$B.vrt
done

make $OUTFILE

