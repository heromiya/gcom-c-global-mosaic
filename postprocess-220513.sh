#! /bin/bash
export WORKDIR=$(mktemp -d)
#export WORKDIR=/tmp/tmp.GkK2NZjkGK
mkdir -p output
INPUT=$(pwd)/RSRF.2000.20201205.wo_noise.tif
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
#    gdalbuildvrt -srcnodata 0 -vrtnodata -32768 -overwrite  $INPUT.vrt $INPUT
    gdal_fillnodata.py -md 2000 -b $B $INPUT $INPUT.filled.$B.tif # -co COMPRESS=Deflate
    #saga_cmd grid_tools 7 -INPUT $INPUT -RESULT $INPUT.filled.$B.sdat
    saga_cmd grid_filter 1 -INPUT $INPUT.filled.$B.tif -RESULT $INPUT.$B.sdat
}
export -f fill_filter

gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata -32768 -te $(echo $LOWER_EXTENT | sed 's/,/ /g') $(pwd)/output/lower.vrt $INPUT
gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata -32768 -te $(echo $UPPER_EXTENT | sed 's/,/ /g') $(pwd)/output/upper.vrt $INPUT

#for INPUT in $(pwd)/output/lower.vrt $(pwd)/output/upper.vrt; do
#    for B in 1 2 3; do
#	fill_filter $INPUT $B
#    done
#done

parallel fill_filter ::: $(pwd)/output/lower.vrt $(pwd)/output/upper.vrt ::: {1..3}

### Middle

gdalbuildvrt -srcnodata 0 -vrtnodata -32768 -te $(echo $MIDDLE_EXTENT | sed 's/,/ /g') output/middle.RSRF.vrt $INPUT
#gdalbuildvrt -srcnodata 0 -vrtnodata -32768 -te $(echo $MIDDLE_EXTENT | sed 's/,/ /g') output/middle.NWLRK.vrt $(pwd)/NWLRK.matched.tif 
#gdalwarp -srcnodata 0 -dstnodata -32768 -te $(echo $MIDDLE_EXTENT | sed 's/,/ /g') output/middle.RSRF.vrt $INPUT
gdalwarp -overwrite -ot Int16 -srcnodata 0 -dstnodata -32768 -te $(echo $MIDDLE_EXTENT | sed 's/,/ /g') -of VRT $(pwd)/NWLRK.matched.tif output/middle.NWLRK.vrt

merge_filter(){ #-srcnodata -32768 -vrtnodata -32768
    B=$1
    gdalbuildvrt -overwrite -b $B output/middle.merged.$B.vrt $(pwd)/output/middle.NWLRK.vrt $(pwd)/output/middle.RSRF.vrt
    saga_cmd grid_filter 1 -INPUT output/middle.merged.$B.vrt -RESULT output/middle.vrt.$B.sdat
}
export -f merge_filter

parallel merge_filter ::: {1..3}

for SEP in middle upper lower; do #
    gdalbuildvrt -separate output/$SEP.filled.vrt $(for B in {1..3}; do printf "$(pwd)/output/$SEP.vrt.$B.sdat "; done)
done

### Merge
gdalbuildvrt output/RSRF.2000.filled.vrt $(for L in lower middle upper; do printf "output/$L.filled.vrt "; done)
#gdalbuildvrt RSRF.2000.filled.vrt /tmp/tmp.hioNe0X12C/lower.filled.vrt /tmp/tmp.O3ngJXYGZy/middle.filled.vrt /tmp/tmp.hioNe0X12C/lower.filled.vrt

### Resize

gdalwarp -overwrite -r cubicspline -s_srs EPSG:4087 -te -20026376.39 -9462156.72 20026376.39 9462156.72 -tr 2000 2000 -co COMPRESS=Deflate -multi output/RSRF.2000.filled.vrt output/RSRF.NWLRK.Res2000.tif

gdal_translate -ot Byte -co COMPRESS=Deflate -scale_1 0 3200 1 255 -scale_2 0 2600 1 255 -scale_3 0 2900 1 255 output/RSRF.NWLRK.Res2000.tif output/RSRF.NWLRK.Res2000.Byte.tif


#for i in {0..10}; do
#    gdalwarp -overwrite -srcnodata "-32768 0" -dstnodata "-32768 0" tmp2.tif tmp1.tif
#done

#    gdal_fillnodata.py -md 1000 -si 1 lower.vrt -co COMPRESS=Deflate lower.fillnodata.tif
#done
