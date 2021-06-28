#! /bin/bash 

export VER=20210406
export DOY=$1
export TILE=$2
export GCP_INTERVAL=100
export RES=2000
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r med -multi -co COMPRESS=Deflate -overwrite"
export PRODUCT=CLFG


mkdir -p $PRODUCT/$RES/$TILE

WORKDIR=$(mktemp -d /tmp/tmp.getRSRF.XXXXX)
DOY=$1
DATE_STRING="jan 1 2019 $DOY days"
export YYYY=$(date --date="$DATE_STRING" +%Y)
export MM=$(date --date="$DATE_STRING" +%m)
export DD=$(date --date="$DATE_STRING" +%d)

export FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.ATMOS.CLFG/2
export H5FILE=CLFG/h5/${YYYY}/${MM}/${DD}/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_CLFGK_2000.h5
mkdir -p $(dirname $H5FILE)

export B=Cloud_flag
export RESAMPLED_TIFF=CLFG/$RES/$TILE/$(basename $H5FILE).$B.$RES.tif
mkdir -p $(dirname $RESAMPLED_TIFF)

make $RESAMPLED_TIFF
rm -rf $WORKDIR
