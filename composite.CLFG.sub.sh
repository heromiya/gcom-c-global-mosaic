#! /bin/bash -x

export TILE=$1
#IN_FILE=$1
export COMPOSITE_FUNCTION=$2
export OUTFILE=$3

composite(){
    WORKDIR=$(mktemp -d)
    X_RANGE=$1
    Y_RANGE=$2
    X_MIN=$(echo $X_RANGE | cut -f 1 -d ",")
    X_MAX=$(echo $X_RANGE | cut -f 2 -d ",")
    Y_MIN=$(echo $Y_RANGE | cut -f 1 -d ",")
    Y_MAX=$(echo $Y_RANGE | cut -f 2 -d ",")

    for B in Cloud_flag; do
	gdalbuildvrt -q -overwrite -te $X_MIN $Y_MIN $X_MAX $Y_MAX $WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.$B.vrt $VRTDIR/$TILE.$B.vrt
    done

    Rscript --vanilla composite.CLFG.R \
	$WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.Cloud_flag.vrt \
	$COMPOSITE_FUNCTION \
	$OUTFILE.$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.tif

    rm -rf $WORKDIR
}
export -f composite

UpperLeft=($(gdalinfo  -json $VRTDIR/$TILE.$B.vrt | jq ".cornerCoordinates.upperLeft" | tr -d "[],"))
LowerRight=($(gdalinfo -json $VRTDIR/$TILE.$B.vrt | jq ".cornerCoordinates.lowerRight" | tr -d "[],"))

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

rm -f $OUTFILE
gdal_merge.py -q -ot Float32 -co COMPRESS=Deflate -o $OUTFILE $OUTFILE.*.tif
rm -f $OUTFILE.*.tif
