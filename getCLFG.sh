#! /bin/bash 

export VER=20210406
export DOY=$1
export TILE=$2
export GCP_INTERVAL=100
export RES=2000
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r med -multi -co COMPRESS=Deflate -overwrite"
export PRODUCT=CLFG


mkdir -p $PRODUCT/$RES/$TILE

#WORKDIR=$(mktemp -d /tmp/tmp.getRSRF.XXXXX)
#DOY=$1
#DATE_STRING="jan 1 $YEAR $DOY days"
#export YYYY=$(date --date="$DATE_STRING" +%Y)
#export MM=$(date --date="$DATE_STRING" +%m)
#export DD=$(date --date="$DATE_STRING" +%d)

#export FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.ATMOS.CLFG/2
#export H5FILE=CLFG/h5/${YYYY}/${MM}/${DD}/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_CLFGK_2000.h5
#mkdir -p $(dirname $H5FILE)

export B=Cloud_flag
#export RESAMPLED_TIFF=CLFG/$RES/$TILE/$(basename $H5FILE).$B.$RES.tif
#mkdir -p $(dirname $RESAMPLED_TIFF)

#make $RESAMPLED_TIFF
#rm -rf $WORKDIR

function h2t() {
    export CLFG_IN=$1
    export CLFG_OUT=CLFG.gtiff/$YYYY/$MM/$DD/$(basename $CLFG_IN)-Cloud_flag.tif
    make $CLFG_OUT
}
export -f h2t

function get_CLFG(){
    export YYYY=$1
    export MM=$2
    export DD=$3

    mkdir -p CLFG/$YYYY/$MM/$DD CLFG.gtiff/$YYYY/$MM/$DD
    cd CLFG/$YYYY/$MM/$DD
    export FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.ATMOS.CLFG/2
    #export H5FILE=CLFG/h5/${YYYY}/${MM}/${DD}/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_CLFGK_2000.h5
    #FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L1B/2
    wget -nc --random-wait --user=heromiya --password=anonymous $FTP/$YYYY/$MM/$DD/*CLFGK_200*.h5

    cd $OLDPWD
    parallel --results log.d/h2t h2t ::: CLFG/$YYYY/$MM/$DD/*.h5

    export GTIFF_DIR=CLFG.gtiff/$YYYY/$MM/$DD/
    
    #parallel --results log.d/merge merge ::: $(find $GTIFF_DIR -type f | sed 's/.*[A-Z]\([0-9]\{3\}\)[0-9]\{2\}.*tif/\1/g' | sort | uniq)
    #for P in  $(find $GTIFF_DIR -type f | sed 's/.*[A-Z]\([0-9]\{3\}\)[0-9]\{2\}.*tif/\1/g' | sort | uniq); do gdalwarp -co compress=deflate -multi $(find $GTIFF_DIR -type f -regex  ".*[A-Z]${P}[0-9][0-9]_.*") $GTIFF_DIR/GC1SG1_${YYYY}${MM}${DD}_${P}-467.tif; done
}
export -f get_CLFG

for YYYY in 2018 2019 2020 2021; do for DD in 06 07 08 09 10 11 12 13; do get_CLFG $YYYY 10 $DD; done; done
