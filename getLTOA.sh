#! /bin/bash 

export VER=20210318
export DOY=$1
export TILE=$2
export GCP_INTERVAL=100
export RES=2000
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r med -multi -co COMPRESS=Deflate -overwrite"
mkdir -p GCOM-C-LTOA/$RES/$TILE
mkdir -p VRT/$RES
mkdir -p GCOM-C-LTOA/composite/$RES/$VER

export OUTFILE=composite/$RES/$VER/composite.LTOA.v2.$RES.$TILE.$VER


WORKDIR=$(mktemp -d /tmp/tmp.getRSRF.XXXXX)
DOY=$1
DATE_STRING="jan 1 2019 $DOY days"
export YYYY=$(date --date="$DATE_STRING" +%Y)
export MM=$(date --date="$DATE_STRING" +%m)
export DD=$(date --date="$DATE_STRING" +%d)

#H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_RSRFQ_1001.h5
#FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.RSRF/1
FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.LTOA/2

export H5FILE=GCOM-C-LTOA/LTOA/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_LTOAK_2002.h5

#sleep $(echo $(( $RANDOM % 60 + 1 )))
#if [ ! -e  GCOM-C-LTOA/$RES/$TILE/$(basename $H5FILE).VN04.tif ]; then

while [ $(ps -aux | grep wget | grep -v grep | wc -l) -gt 0 ]; do
    sleep $(echo $(( $RANDOM % 60 + 1 )))
done

#wget -q --random-wait -nc --user=heromiya --password=anonymous $FTP/$YYYY/$MM/$DD/$(basename $H5FILE) -O $H5FILE
if [ $? -eq 0 ]; then
    for B in VN04 VN06 VN07; do # Lt_VN10 VN03 VN05 VN07
	export B
	export RESAMPLED_TIFF=GCOM-C-LTOA/$RES/$TILE/$(basename $H5FILE).$B.$RES.tif
	make $RESAMPLED_TIFF
    done
fi
#fi
rm -rf $WORKDIR
