#! /bin/bash

export TILE=$1
export BUF=$2
export VER=20210328_$(printf %02d $BUF)
export RES=2000
export VRTDIR=VRT/LTOA/$RES/$(printf %02d $BUF)
mkdir -p $VRTDIR

export OUTFILE=composite/LTOA/$RES/$VER/composite.$RES.$TILE.$VER
mkdir -p $(dirname $OUTFILE)

for B in VN04 VN06 VN07 ; do
    export B
    export INPUT_FILES=$(find $PWD/GCOM-C-LTOA/$RES/$TILE/ -type f -regex ".*201910.*T$TILE.*LTOAK.*.$B.tif" | grep $(for BUF in {3..1}; do printf "10%02d\|" $(expr 9 - $BUF); done)"1009\|"$(for BUF in {1..3}; do printf "10%02d\|" $(expr 9 + $BUF); done | sed 's/\\|$//g;') | awk 'BEGIN{ORS=" "}{print}'| sort)
    make $VRTDIR/$TILE.$B.vrt
done

composite(){
    WORKDIR=$(mktemp -d)
    X_RANGE=$1
    Y_RANGE=$2
    X_MIN=$(echo $X_RANGE | cut -f 1 -d ",")
    X_MAX=$(echo $X_RANGE | cut -f 2 -d ",")
    Y_MIN=$(echo $Y_RANGE | cut -f 1 -d ",")
    Y_MAX=$(echo $Y_RANGE | cut -f 2 -d ",")

    for B in VN04 VN06 VN07; do
	gdalbuildvrt -te $X_MIN $Y_MIN $X_MAX $Y_MAX $WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.$B.vrt $VRTDIR/$TILE.$B.vrt
    done

    Rscript composite.LTOA.R \
	$WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.VN04.vrt \
	$WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.VN06.vrt \
	$WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.VN07.vrt \
	$OUTFILE.$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.tif

    rm -rf $WORKDIR
}
export -f composite

UpperLeft=($(gdalinfo -json VRT/$RES/$TILE.VN04.vrt | jq ".cornerCoordinates.upperLeft" | tr -d "[],"))
LowerRight=($(gdalinfo -json VRT/$RES/$TILE.VN04.vrt | jq ".cornerCoordinates.lowerRight" | tr -d "[],"))

N_INT=4
H_INTERVAL=$(perl -e "print( (${LowerRight[0]} - ${UpperLeft[0]}) / $N_INT )")
V_INTERVAL=$(perl -e "print( (${UpperLeft[1]} - ${LowerRight[1]}) / $N_INT )")

H_1=$(mktemp)
H_2=$(mktemp)
V_1=$(mktemp)
V_2=$(mktemp)

echo 0 > $H_1
seq ${UpperLeft[0]} $H_INTERVAL ${LowerRight[0]} >> $H_1
seq ${UpperLeft[0]} $H_INTERVAL ${LowerRight[0]} >  $H_2

echo 0 > $V_1
seq ${LowerRight[1]} $V_INTERVAL ${UpperLeft[1]} >> $V_1
seq ${LowerRight[1]} $V_INTERVAL ${UpperLeft[1]} >  $V_2

parallel composite ::: $(paste $H_1 $H_2 | tail -n +2 | head -n -1 | awk '{printf("%lf,%lf ",$1,$2) }') ::: $(paste $V_1 $V_2 | tail -n +2 | head -n -1 | awk '{printf("%lf,%lf ",$1,$2) }')
#for X_RANGE in $(paste $H_1 $H_2 | tail -n +2 | head -n -1 | awk '{printf("%lf,%lf ",$1,$2) }'); do
#    for Y_RANGE in  $(paste $V_1 $V_2 | tail -n +2 | head -n -1 | awk '{printf("%lf,%lf ",$1,$2) }'); do
#	composite $X_RANGE $Y_RANGE
#    done
#done


rm -f $OUTFILE.tif
gdal_merge.py -ot Float32 -co COMPRESS=Deflate -o $OUTFILE.tif $OUTFILE.*.tif
rm -f $OUTFILE.*.tif



#for B in {1..3}; do 
#    gdal_translate -ot Int16 -a_srs EPSG:4087 -a_ullr ${UpperLeft[0]} ${UpperLeft[1]} ${LowerRight[0]} ${LowerRight[1]} -a_nodata -32768 $OUTFILE.$B.tif $OUTFILE.$B.geo.tif
#done

#gdal_merge.py -separate -ot Int16 -n 0 -a_nodata -32768 -o $OUTFILE.tif $OUTFILE.3.geo.tif $OUTFILE.2.geo.tif $OUTFILE.1.geo.tif
#rm -f $OUTFILE.R.tif $OUTFILE.G.tif $OUTFILE.B.tif

#gdalwarp -r cubicspline -s_srs EPSG:4087 -te -20026376.39 -9462156.72 20026376.39 9462156.72 -multi -tr 5006.594098 4731.07836 -co compress=deflate 2000.v2.vrt 2000.v2.tif
#EOF
