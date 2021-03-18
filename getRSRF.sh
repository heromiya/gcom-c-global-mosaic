#! /bin/bash

export VER=20210304
export TILE=$1
export GCP_INTERVAL=200
export RES=250
export WARPOPT="-q -s_srs EPSG:4326 -t_srs EPSG:4087 -tr $RES $RES -tps -r med -multi -co COMPRESS=Deflate -overwrite"
mkdir -p GCOM-C/$RES/$TILE
mkdir -p VRT/$RES
mkdir -p composite/$RES/$VER

export OUTFILE=composite/$RES/$VER/composite.v2.$RES.$TILE.$VER

getRSRF() {
    WORKDIR=$(mktemp -d /tmp/tmp.getRSRF.XXXXX)
    DOY=$1
    DATE_STRING="jan 1 2020 $DOY days"
    export YYYY=$(date --date="$DATE_STRING" +%Y)
    export MM=$(date --date="$DATE_STRING" +%m)
    export DD=$(date --date="$DATE_STRING" +%d)
    
    #H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_RSRFQ_1001.h5
    #FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.RSRF/1

    H5FILE=$WORKDIR/GC1SG1_${YYYY}${MM}${DD}D01D_T${TILE}_L2SG_RSRFQ_2000.h5
    FTP=ftp://ftp.gportal.jaxa.jp/standard/GCOM-C/GCOM-C.SGLI/L2.LAND.RSRF/2

    #sleep $(echo $(( $RANDOM % 60 + 1 )))
    if [ ! -e  GCOM-C/$RES/$TILE/$(basename $H5FILE).VN04.tif ]; then
	
	#while [ $(ps -aux | grep wget | grep -v grep | wc -l) -gt 0 ]; do
	#    sleep $(echo $(( $RANDOM % 60 + 1 )))
	#done
	
	wget -q --random-wait -nc --user=heromiya --password=anonymous $FTP/$YYYY/$MM/$DD/$(basename $H5FILE) -O $H5FILE
	if [ $? -eq 0 ]; then
	    for B in VN04 VN06 VN07 VN10; do # VN03 VN05 VN07 
      		python3 h5_2_tiff.py $H5FILE Rs_${B} $H5FILE.$B.tif $GCP_INTERVAL
		gdalwarp $WARPOPT $H5FILE.$B.tif GCOM-C/$RES/$TILE/$(basename $H5FILE).$B.tif
	    done
	fi
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
#for i in {268..273}; do getRSRF $i; done

parallel --bar getRSRF ::: {0..365}


for B in VN04 VN06 VN07 VN10 ; do #
    gdalbuildvrt -q -separate -overwrite VRT/$RES/$TILE.$B.vrt $(pwd)/GCOM-C/$RES/$TILE/*T${TILE}*RSRF*.$B.tif
done

composite(){
    WORKDIR=$(mktemp -d)
    X_RANGE=$1
    Y_RANGE=$2
    X_MIN=$(echo $X_RANGE | cut -f 1 -d ",")
    X_MAX=$(echo $X_RANGE | cut -f 2 -d ",")
    Y_MIN=$(echo $Y_RANGE | cut -f 1 -d ",")
    Y_MAX=$(echo $Y_RANGE | cut -f 2 -d ",")

    for B in VN04 VN06 VN07 VN10; do
	gdalbuildvrt -q -te $X_MIN $Y_MIN $X_MAX $Y_MAX $WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.$B.vrt VRT/$RES/$TILE.$B.vrt
    done

    #OUTFILE=NWLR/NWLRK.$X_MIN.$Y_MIN.$X_MAX.$Y_MAX
    Rscript composite.R \
	$WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.VN04.vrt \
	$WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.VN06.vrt \
	$WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.VN07.vrt \
	$WORKDIR/$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.VN10.vrt \
	$OUTFILE.$X_MIN.$Y_MIN.$X_MAX.$Y_MAX.tif

#    rm -f $OUTFILE.tif
#    gdal_merge.py -separate -co COMPRESS=Deflate -o $OUTFILE.tif $OUTFILE.R.tif $OUTFILE.G.tif $OUTFILE.B.tif  # -n 0 -a_nodata -32768
#    rm -f $OUTFILE.R.tif $OUTFILE.G.tif $OUTFILE.B.tif

    rm -rf $WORKDIR
}
export -f composite

UpperLeft=($(gdalinfo -json VRT/$RES/$TILE.VN04.vrt | jq ".cornerCoordinates.upperLeft" | tr -d "[],"))
LowerRight=($(gdalinfo -json VRT/$RES/$TILE.VN04.vrt | jq ".cornerCoordinates.lowerRight" | tr -d "[],"))

N_INT=64
H_INTERVAL=$(perl -e "print( (${LowerRight[0]} - ${UpperLeft[0]}) / $N_INT )")
V_INTERVAL=$(perl -e "print( (${UpperLeft[1]} - ${LowerRight[1]}) / $N_INT )")

H_1=$(mktemp)
H_2=$(mktemp)
V_1=$(mktemp)
V_2=$(mktemp)

echo 0 > $H_1
seq ${UpperLeft[0]} $H_INTERVAL ${LowerRight[0]} >> $H_1
seq ${UpperLeft[0]} $H_INTERVAL ${LowerRight[0]} >  $H_2

echo 0 > $V_1
seq ${LowerRight[1]} $V_INTERVAL ${UpperLeft[1]} >> $V_1
seq ${LowerRight[1]} $V_INTERVAL ${UpperLeft[1]} >  $V_2


parallel composite ::: $(paste $H_1 $H_2 | tail -n +2 | head -n -1 | awk '{printf("%lf,%lf ",$1,$2) }') ::: $(paste $V_1 $V_2 | tail -n +2 | head -n -1 | awk '{printf("%lf,%lf ",$1,$2) }')

rm -f $OUTFILE.tif
gdal_merge.py -ot Int16 -n 0 -a_nodata -32768 -co COMPRESS=Deflate -o $OUTFILE.tif $OUTFILE.*.tif
rm -f $OUTFILE.*.tif



#for B in {1..3}; do 
#    gdal_translate -ot Int16 -a_srs EPSG:4087 -a_ullr ${UpperLeft[0]} ${UpperLeft[1]} ${LowerRight[0]} ${LowerRight[1]} -a_nodata -32768 $OUTFILE.$B.tif $OUTFILE.$B.geo.tif
#done

#gdal_merge.py -separate -ot Int16 -n 0 -a_nodata -32768 -o $OUTFILE.tif $OUTFILE.3.geo.tif $OUTFILE.2.geo.tif $OUTFILE.1.geo.tif
#rm -f $OUTFILE.R.tif $OUTFILE.G.tif $OUTFILE.B.tif

#gdalwarp -r cubicspline -s_srs EPSG:4087 -te -20026376.39 -9462156.72 20026376.39 9462156.72 -multi -tr 5006.594098 4731.07836 -co compress=deflate 2000.v2.vrt 2000.v2.tif
