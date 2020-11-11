#! /bin/bash

export TILE=0529
export GCP_INTERVAL=100
export RES=1000
#export YEAR=2019
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r lanczos -multi -co COMPRESS=Deflate -overwrite"

mkdir -p GCOM-C/$TILE
mkdir -p VRT

getRSRF() {
    WORKDIR=$(mktemp -d)
    DOY=$1
    DATE_STRING="jan 1 2020 $DOY days"
    export YYYY=$(date --date="$DATE_STRING" +%Y)
    export MM=$(date --date="$DATE_STRING" +%m)
    export DD=$(date --date="$DATE_STRING" +%d)

    H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_RSRFQ_2000.h5
    #H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_LTOAK_1002.h5
    FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.RSRF
    #FTP="ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.LTOA"
    
    wget -q -nc --user=heromiya --password=anonymous $FTP/2/$YYYY/$MM/$DD/$(basename $H5FILE) -O $H5FILE
    for B in VN04 VN06 VN07 VN10; do # VN03 VN05 VN07
      	python3 h5_2_tiff.py $H5FILE Rs_${B} $H5FILE.$B.tif $GCP_INTERVAL
	gdalwarp $WARPOPT $H5FILE.$B.tif GCOM-C/$TILE/$(basename $H5FILE).$B.tif
    done

    # Not stable to use resampled products.
    #    VGI_H5FILE=GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_VGI_Q_2000.h5
    #    wget -nc --user=heromiya --password=anonymous ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.VGI_/2/$YYYY/$MM/$DD/$VGI_H5FILE -O GCOM-C/$VGI_H5FILE
    #    python3 h5_2_tiff.py GCOM-C/$VGI_H5FILE EVI $WORKDIR/$VGI_H5FILE.EVI.tif $GCP_INTERVAL
    #    gdalwarp $WARPOPT $WORKDIR/$VGI_H5FILE.EVI.tif GCOM-C/$VGI_H5FILE.EVI.tif
    rm -rf $WORKDIR
}
export -f getRSRF

#parallel getRSRF ::: {366..730}
parallel getRSRF ::: {0..14} #314
#for i in {268..273}; do getRSRF $i; done
for B in VN04 VN06 VN07 VN10; do
    gdalbuildvrt -separate -overwrite VRT/$TILE.$B.vrt $(pwd)/GCOM-C/$TILE/*T${TILE}*RSRF*.$B.tif
done

Rscript composite.R VRT/$TILE.VN04.vrt VRT/$TILE.VN06.vrt VRT/$TILE.VN07.vrt VRT/$TILE.VN10.vrt out.v2.100.250.tif
