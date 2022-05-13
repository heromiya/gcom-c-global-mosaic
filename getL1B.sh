#! /bin/bash 

export VER=20220407
export DOY=$1
#export TILE=$2
export GCP_INTERVAL=100
export RES=2000
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r med -multi -co COMPRESS=Deflate -overwrite"
export PRODUCT=L1B

mkdir -p $PRODUCT/$RES/$TILE

WORKDIR=$(mktemp -d /tmp/tmp.getRSRF.XXXXX)
#DOY=$1
#DATE_STRING="jan 1 2019 $DOY days"
#export YYYY=$(date --date="$DATE_STRING" +%Y)
#export MM=$(date --date="$DATE_STRING" +%m)
#export DD=$(date --date="$DATE_STRING" +%d)

function h2t() {
    export L1B_IN=$1
    export L1B_OUT=L1B.gtiff/$YYYY/$MM/$DD/$(basename $L1B_IN)-467.tif
    make $L1B_OUT
}
export -f h2t

function merge() {
    P=$1
    gdalwarp -co compress=deflate -multi $(find $GTIFF_DIR -type f -regex  ".*[A-Z]${P}[0-9][0-9]_.*") $GTIFF_DIR/GC1SG1_${YYYY}${MM}${DD}_${P}-467.tif

}
export -f merge

function get_L1B(){
    export YYYY=$1
    export MM=$2
    export DD=$3

    mkdir -p L1B/$YYYY/$MM/$DD L1B.gtiff/$YYYY/$MM/$DD
    cd L1B/$YYYY/$MM/$DD
    FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L1B/2
    wget -nc --random-wait --user=heromiya --password=anonymous $FTP/$YYYY/$MM/$DD/*VNRDL_200*.h5

    cd $OLDPWD
    parallel --results log.d/h2t h2t ::: L1B/$YYYY/$MM/$DD/*.h5

    export GTIFF_DIR=L1B.gtiff/$YYYY/$MM/$DD/
    
    parallel --results log.d/merge merge ::: $(find $GTIFF_DIR -type f | sed 's/.*[A-Z]\([0-9]\{3\}\)[0-9]\{2\}.*tif/\1/g' | sort | uniq)
    #for P in  $(find $GTIFF_DIR -type f | sed 's/.*[A-Z]\([0-9]\{3\}\)[0-9]\{2\}.*tif/\1/g' | sort | uniq); do gdalwarp -co compress=deflate -multi $(find $GTIFF_DIR -type f -regex  ".*[A-Z]${P}[0-9][0-9]_.*") $GTIFF_DIR/GC1SG1_${YYYY}${MM}${DD}_${P}-467.tif; done
}
export -f get_L1B

for YYYY in 2018 2019 2020 2021; do for DD in 06 07 08 09 10 11 12 13; do get_L1B $YYYY 10 $DD; done; done
#get_L1B 2019 10 09

#parallel get_hdf {1} 10 {2} ::: 2018 2019 2020 2021 ::: 06 07 08 09 10 11 12 13




#parallel ./SGLI_geo_map_linux.exe {1} -m -d Image_data/{2} -o L1B.gtiff/$YYYY/$MM/$DD ::: L1B/$YYYY/$MM/$DD/*.h5 ::: Lt_VN07 Lt_VN06 Lt_VN04

#export H5FILE=L1B/h5/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_1BSG_VNRDK_2002.h5
#GC1SG1_201903020053P04207_1BSG_VNRDK_2002.h5


#sleep $(echo $(( $RANDOM % 60 + 1 )))
#if [ ! -e  GCOM-C-LTOA/$RES/$TILE/$(basename $H5FILE).VN04.tif ]; then

#while [ $(ps -aux | grep wget | grep -v grep | wc -l) -gt 0 ]; do
#    sleep $(echo $(( $RANDOM % 60 + 1 )))
#done

#wget -q --random-wait -nc --user=heromiya --password=anonymous $FTP/$YYYY/$MM/$DD/$(basename $H5FILE) -O $H5FILE
#if [ $? -eq 0 ]; then
#    for B in VN04 VN06 VN07; do # Lt_VN10 VN03 VN05 VN07
#	export B
#	export RESAMPLED_TIFF=GCOM-C-LTOA/$RES/$TILE/$(basename $H5FILE).$B.$RES.tif
#	make $RESAMPLED_TIFF
#    done
#fi
#fi
rm -rf $WORKDIR
