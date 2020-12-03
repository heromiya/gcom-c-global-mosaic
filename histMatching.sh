#! /bin/bash

WORKDIR=$(mktemp -d)

INPUT=NWLRK.vrt
REF=RSRF.2000.wo_noise.tif
OUT_TIFF=NWLRK.matched.tif

REF_XMIN=15841217.0
REF_YMIN=2139140.8
REF_XMAX=19415258.7
REF_YMAX=4506505.4

gdalbuildvrt -overwrite NWLRK.vrt NWLR/*.tif

for B in {1..3}; do
    gdal_translate -of SAGA -b $B -projwin $REF_XMIN $REF_YMAX $REF_XMAX $REF_YMIN $REF $WORKDIR/$B.sdat
    gdal_translate -of SAGA -b $B $INPUT $WORKDIR/input.$B.sdat    
    saga_cmd grid_calculus 21 -GRID $WORKDIR/input.$B.sdat -MATCHED $WORKDIR/matched.$B.sdat -REFERENCE $WORKDIR/$B.sdat -METHOD 1 -NCLASSES 10000 -MAXSAMPLES 1000000
done

rm -f $OUT_TIFF
gdal_merge.py -separate -co COMPRESS=Deflate -o $OUT_TIFF $(for B in {1..3}; do printf "$WORKDIR/matched.$B.sdat "; done)

gdalbuildvrt -srcnodata 0 RSRF.NWLRK.merged.vrt NWLRK.matched.tif RSRF.2000.wo_noise.tif
