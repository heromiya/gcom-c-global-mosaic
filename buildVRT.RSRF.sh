#! /bin/bash
export RES=2000
buildVRT() {
    VV=$1
    HH=$2
    TILE=$(printf %02d%02d $VV $HH)
    for B in VN04 VN06 VN07 VN10 ; do #
	gdalbuildvrt -separate -overwrite VRT/$RES/$TILE.$B.vrt $(pwd)/GCOM-C/$RES/$TILE/*T${TILE}*RSRF*.$B.tif
    done
}
export -f buildVRT
parallel buildVRT ::: {0..17} ::: {0..35}

for B in VN04 VN06 VN07 VN10; do
    gdalbuildvrt -overwrite VRT/2000.$B.vrt $(pwd)/VRT/2000/*.$B.vrt
done
