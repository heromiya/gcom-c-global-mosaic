#! /bin/bash

export TILE=$1
export GCP_INTERVAL=200
export RES=2000
#export YEAR=2019  -r lanczos  -r average
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r med -multi -co COMPRESS=Deflate -srcnodata  -9999 -dstnodata -9999 -overwrite"
export THRESHOLD=10
mkdir -p GCOM-C/$RES/NWLR/$TILE
mkdir -p VRT/$RES/NWLR
mkdir -p composite/$RES/NWLR

export OUTFILE=composite/$RES/NWLR/NWLR.composite.v2.$RES.$TILE.$THRESHOLD.tif

getRSRF() {
    WORKDIR=$(mktemp -d)
    DOY=$1
    DATE_STRING="jan 1 2020 $DOY days"
    export YYYY=$(date --date="$DATE_STRING" +%Y)
    export MM=$(date --date="$DATE_STRING" +%m)
    export DD=$(date --date="$DATE_STRING" +%d)
    
    #H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}*${TILE}_L2SG_NWLRQ_2001.h5
    FTP="ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.OCEAN.NWLR/2/GC1SG1_${YYYY}${MM}${DD}*${TILE}_L2SG_NWLRQ_2001.h5"
    
    cd $WORKDIR
    wget -q -nc --user=heromiya --password=anonymous $FTP/$YYYY/$MM/$DD/$(basename $H5FILE)
    for H5FILE in GC1SG1_${YYYY}${MM}${DD}*${TILE}_L2SG_NWLRQ_2001.h5; do
	if [ ! -e  GCOM-C/$RES/NWLR/$TILE/$(basename $H5FILE).490.tif ]; then
	    for B in 490 565 670; do 
      		python3 L2_scene.py $H5FILE NWLR_${B} $H5FILE.$B.tif #$GCP_INTERVAL
		gdalwarp $WARPOPT $H5FILE.$B.tif GCOM-C/$RES/NWLR/$TILE/$(basename $H5FILE).$B.tif
	    done
	fi
    done


    cd $OLDPWD
    rm -rf $WORKDIR
}
export -f getRSRF

#parallel getRSRF ::: {366..730}
#parallel getRSRF ::: {0..6} #314
#parallel --bar getRSRF ::: {0..14}
parallel getRSRF ::: {0..331}
#for i in {268..273}; do getRSRF $i; done

for B in 490 565 670; do #
    gdalbuildvrt -separate -overwrite VRT/$RES/NWLR/$TILE.$B.vrt $(pwd)/GCOM-C/$RES/NWLR/$TILE/*${TILE}_L2SG_NWLRQ*.$B.tif
done

Rscript composite.R VRT/$RES/NWLR/$TILE.490.vrt VRT/$RES/NWLR/$TILE.565.vrt VRT/$RES/NWLR/$TILE.670.vrt $OUTFILE