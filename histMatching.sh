#! /bin/bash

WORKDIR=$(mktemp -d)

REF_XMIN=15841217.0
REF_YMIN=2139140.8
REF_XMAX=19415258.7
REF_YMAX=4506505.4

for B in {1..3}; do
    gdal_translate -of SAGA -b $B -projwin $REF_XMIN $REF_YMAX $REF_XMAX $REF_YMIN RSRF.2000.wo_noise.tif $WORKDIR/$B    

done
