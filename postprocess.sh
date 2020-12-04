#! /bin/bash
export WORKDIR=$(mktemp -d)
#export WORKDIR=/tmp/tmp.fumekqUGrK

UPPER_EXTENT=-20026376.39,6704500.2,20026376.39,9462156.72
MIDDLE_EXTENT=-20026376.39,-7164200.9,20026376.39,6704500.2
LOWER_EXTENT=-20026376.39,-9462156.72,20026376.39,-7164200.9

#XMIN=-7273067.5
#XMIN=-3724623.7
#XMAX=-3224623.7

#UPPER_EXTENT=$XMIN,6704500.2,$XMAX,9974440.772
#MIDDLE_EXTENT=$XMIN,-7164200.9,$XMAX,6704500.2
#LOWER_EXTENT=$XMIN,-9974440.772,$XMAX,-7164200.9

fill_filter(){
    INPUT=$1
    B=$2
    gdal_fillnodata.py $INPUT -b $B -co COMPRESS=Deflate $INPUT.filled.$B.tif
    saga_cmd grid_filter 1 -INPUT $INPUT.filled.$B.tif -RESULT $INPUT.$B.sdat
}
export -f fill_filter

gdalbuildvrt -overwrite -srcnodata -32768 -vrtnodata -32768 -te $(echo $LOWER_EXTENT | sed 's/,/ /g') $WORKDIR/lower.vrt RSRF.2000.wo_noise.tif
gdalbuildvrt -overwrite -srcnodata -32768 -vrtnodata -32768 -te $(echo $UPPER_EXTENT | sed 's/,/ /g') $WORKDIR/upper.vrt RSRF.2000.wo_noise.tif

parallel fill_filter ::: $WORKDIR/lower.vrt $WORKDIR/upper.vrt ::: {1..3}

### Middle

gdalbuildvrt -srcnodata -32768 -vrtnodata -32768 -te $(echo $MIDDLE_EXTENT | sed 's/,/ /g') $WORKDIR/middle.RSRF.vrt  RSRF.2000.wo_noise.tif
gdalbuildvrt -srcnodata 0 -vrtnodata -32768      -te $(echo $MIDDLE_EXTENT | sed 's/,/ /g') $WORKDIR/middle.NWLRK.vrt NWLRK.matched.tif 

merge_filter(){
    B=$1
    gdalbuildvrt -overwrite -srcnodata -32768 -vrtnodata -32768 -b $B $WORKDIR/middle.merged.$B.vrt $WORKDIR/middle.NWLRK.vrt $WORKDIR/middle.RSRF.vrt
    saga_cmd grid_filter 1 -INPUT $WORKDIR/middle.merged.$B.vrt -RESULT $WORKDIR/middle.vrt.$B.sdat
}
export -f merge_filter

parallel merge_filter ::: {1..3}

for SEP in upper lower middle; do
    gdalbuildvrt -separate $WORKDIR/$SEP.filled.vrt $(for B in {1..3}; do printf "$WORKDIR/$SEP.vrt.$B.sdat "; done)
done

### Merge
gdalbuildvrt RSRF.2000.filled.vrt $(for L in lower middle uppper; do printf "$WORKDIR/$L.filled.vrt "; done)

#for i in {0..10}; do
#    gdalwarp -overwrite -srcnodata "-32768 0" -dstnodata "-32768 0" tmp2.tif tmp1.tif
#done

#    gdal_fillnodata.py -md 1000 -si 1 lower.vrt -co COMPRESS=Deflate lower.fillnodata.tif
#done
