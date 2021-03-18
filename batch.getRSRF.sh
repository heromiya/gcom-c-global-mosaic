#for HH in {0..35}; do
#    for VV in {0..17}; do
#for HH in {15..15}; do
#    for VV in {0..0}; do
#	TILE=$(printf %02d%02d $VV $HH)
#	echo "0619 0528 0529 0113 0117 0214 1513 1615 1618 0313" | grep $TILE
#	if [ $? -ne 0 ]; then
#	    bash getRSRF.sh $TILE
#	fi
#    done
#done

find GCOM-C/250/ -type f | sed 's/.*_T\([0-9]\{4\}\)_.*/\1/g' | sort | uniq > TileNum.lst
for TILE in $(cat TileNum.lst); do
    ./getRSRF.sh $TILE
done

#parallel -j50% --shuf --joblog getRSRF.sh.log ./getRSRF.sh {1}{2} ::: {00..17} ::: {00..35}
