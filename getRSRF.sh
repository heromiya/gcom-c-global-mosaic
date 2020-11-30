#! /bin/bash

export TILE=$1
export GCP_INTERVAL=200
export RES=2000
#export YEAR=2019  -r lanczos  -r average
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r med -multi -co COMPRESS=Deflate -overwrite"
export THRESHOLD=10
mkdir -p GCOM-C/$RES/$TILE
mkdir -p VRT/$RES
mkdir -p composite/$RES

export OUTFILE=composite/$RES/composite.v2.$RES.$TILE.$THRESHOLD

getRSRF() {
    WORKDIR=$(mktemp -d)
    DOY=$1
    DATE_STRING="jan 1 2020 $DOY days"
    export YYYY=$(date --date="$DATE_STRING" +%Y)
    export MM=$(date --date="$DATE_STRING" +%m)
    export DD=$(date --date="$DATE_STRING" +%d)
    
    #H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_RSRFQ_1001.h5
    #FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.RSRF/1

    H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_RSRFQ_2000.h5
    FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.RSRF/2

    if [ ! -e  GCOM-C/$RES/$TILE/$(basename $H5FILE).VN04.tif ]; then
	wget -q -nc --user=heromiya --password=anonymous $FTP/$YYYY/$MM/$DD/$(basename $H5FILE) -O $H5FILE
	for B in VN04 VN06 VN07 VN10; do # VN03 VN05 VN07 
      	    python3 h5_2_tiff.py $H5FILE Rs_${B} $H5FILE.$B.tif $GCP_INTERVAL
	    gdalwarp $WARPOPT $H5FILE.$B.tif GCOM-C/$RES/$TILE/$(basename $H5FILE).$B.tif
	done
    fi

    #H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}*${TILE}_L2SG_NWLRQ_2001.h5
    #FTP="ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.OCEAN.NWLR/2"


    # Not stable to use resampled products.
    #VGI_H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_VGI_Q_2000.h5
    #wget -nc --user=heromiya --password=anonymous ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.VGI_/2/$YYYY/$MM/$DD/$(basename $VGI_H5FILE) -O $VGI_H5FILE
    #python3 h5_2_tiff.py $VGI_H5FILE EVI $VGI_H5FILE.EVI.tif $GCP_INTERVAL
    #gdalwarp $WARPOPT $VGI_H5FILE.EVI.tif GCOM-C/$TILE/$(basename $VGI_H5FILE).EVI.tif

    rm -rf $WORKDIR
}
export -f getRSRF

#parallel getRSRF ::: {366..730}
#parallel getRSRF ::: {0..6} #314
#parallel --bar getRSRF ::: {0..14}
parallel getRSRF ::: {0..331}
#for i in {268..273}; do getRSRF $i; done

for B in VN04 VN06 VN07 VN10 ; do #
    gdalbuildvrt -separate -overwrite VRT/$RES/$TILE.$B.vrt $(pwd)/GCOM-C/$RES/$TILE/*T${TILE}*RSRF*.$B.tif
done

Rscript composite.R VRT/$RES/$TILE.VN04.vrt VRT/$RES/$TILE.VN06.vrt VRT/$RES/$TILE.VN07.vrt VRT/$RES/$TILE.VN10.vrt $OUTFILE $THRESHOLD

gdalbuildvrt $OUTFILE.vrt $OUTFILE.R.tif  $OUTFILE.G.tif  $OUTFILE.B.tif 
#gdalwarp -r cubicspline -s_srs EPSG:4087 -te -20026376.39 -9462156.72 20026376.39 9462156.72 -multi -tr 5006.594098 4731.07836 -co compress=deflate 2000.v2.vrt 2000.v2.tif
