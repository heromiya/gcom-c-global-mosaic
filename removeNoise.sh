#! /bin/bash
WORKDIR=$(mktemp -d)
gdalbuildvrt -overwrite RSRF.2000.vrt composite/2000/*.tif
for B in {1..3}; do
    gdal_calc.py --calc="numpy.where ( numpy.logical_or (A / ( B + 1 ) > 2.9, C == 0), NaN, D)" --outfile=$WORKDIR/$B.denoise.tif -A RSRF.2000.vrt --A_band=1 -B RSRF.2000.vrt --B_band=2 -C RSRF.2000.vrt --C_band=3 -D RSRF.2000.vrt --D_band=$B
    gdal_fillnodata.py -q -md 2 -si 1 $WORKDIR/$B.denoise.tif $WORKDIR/$B.tif
done
OUTFILE=RSRF.2000.wo_noise.tif
rm -f $OUTFILE
gdal_merge.py -separate -o $OUTFILE -co COMPRESS=Deflate $WORKDIR/1.tif $WORKDIR/2.tif $WORKDIR/3.tif 

rm -rf $WORKDIR
