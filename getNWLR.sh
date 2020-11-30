#! /bin/bash

export GCP_INTERVAL=200
export RES=2000
#export YEAR=2019  -r lanczos  -r average
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r med -multi -co COMPRESS=Deflate -srcnodata  -9999 -dstnodata -9999 -overwrite"
export THRESHOLD=10
mkdir -p GCOM-C/$RES/NWLR/$TILE
mkdir -p VRT/$RES/NWLR
mkdir -p composite/$RES/NWLR


getRSRF() {
    WORKDIR=$(mktemp -d)
    DOY=$1
    DATE_STRING="jan 1 2020 $DOY days"
    export YYYY=$(date --date="$DATE_STRING" +%Y)
    export MM=$(date --date="$DATE_STRING" +%m)
    export DD=$(date --date="$DATE_STRING" +%d)
    
    mkdir -p GCOM-C/$RES/NWLR/${YYYY}/${MM}/${DD}/

    #H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}*${TILE}_L2SG_NWLRQ_2001.h5
    #FTP="ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.OCEAN.NWLR/2/$YYYY/$MM/$DD/GC1SG1_${YYYY}${MM}${DD}*${TILE}_L2SG_NWLRQ_2001.h5"
    FTP="ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.OCEAN.NWLR/2/$YYYY/$MM/$DD/GC1SG1_${YYYY}${MM}${DD}*_L2SG_NWLRK_*.h5"
    cp L2_scene.py $WORKDIR/
    cd $WORKDIR
    wget -nc -q --user=heromiya --password=anonymous $FTP #/$YYYY/$MM/$DD/$(basename $H5FILE)
    cd $OLDPWD
    for H5FILE in $WORKDIR/GC1SG1_${YYYY}${MM}${DD}*_L2SG_NWLRK_*.h5; do
	gdalinfo GCOM-C/$RES/NWLR/${YYYY}/${MM}/${DD}/$(basename $H5FILE).670.tif > /dev/null
	if [ $? -ne 0  ]; then
	    for B in 490 565 670; do
      		python3 L2_scene.py $H5FILE NWLR_${B} $H5FILE.$B.tif
		gdalwarp $WARPOPT $H5FILE.$B.tif GCOM-C/$RES/NWLR/${YYYY}/${MM}/${DD}/$(basename $H5FILE).$B.tif
	    done
	fi
    done
    rm -rf $WORKDIR
    for B in 490 565 670; do
	gdalbuildvrt -overwrite GCOM-C/$RES/NWLR/${YYYY}/${MM}/${DD}.$B.vrt GCOM-C/$RES/NWLR/${YYYY}/${MM}/${DD}/*_L2SG_NWLRK_*.$B.tif
    done
}
export -f getRSRF

#parallel -j 100% getRSRF ::: {0..331}

for B in 490 565 670; do
    gdalbuildvrt -separate -overwrite VRT/$RES/NWLR/$B.vrt $(find $(pwd)/GCOM-C/$RES/NWLR/ -type f -regex ".*\.$B\.vrt" | sort | head -n 1)
done

#export OUTFILE=composite/$RES/NWLR/NWLR.composite.v2.$RES.$TILE.$THRESHOLD.tif

composite(){
    WORKDIR=$(mktemp -d)
    X_RANGE=$1
    Y_RANGE=$2
    X_MIN=$(echo $X_RANGE | cut -f 1 -d ",")
    X_MAX=$(echo $X_RANGE | cut -f 2 -d ",")
    Y_MIN=$(echo $Y_RANGE | cut -f 1 -d ",")
    Y_MAX=$(echo $Y_RANGE | cut -f 2 -d ",")

    for B in 490 565 670; do
	gdalbuildvrt -te $X_MIN $Y_MIN $X_MAX $Y_MAX $WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.$B.vrt VRT/$RES/NWLR/$B.vrt
    done

    OUTFILE=NWLRK.$X_MIN.$Y_MIN.$X_MAX.$Y_MAX
    Rscript compositeNWLR.R $WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.490.vrt $WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.565.vrt $WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.670.vrt $OUTFILE

    #rm -f $OUTFILE.tif
    gdal_merge.py -separate -o $OUTFILE.tif $OUTFILE.R.tif $OUTFILE.G.tif $OUTFILE.B.tif  # -n 0 -a_nodata -32768
    #rm -f $OUTFILE.R.tif $OUTFILE.G.tif $OUTFILE.B.tif

    rm -rf $WORKDIR
}
export -f composite

parallel composite ::: -20026376.39,0 0,20026376.39 ::: -9462156.72,0 0,9462156.72
