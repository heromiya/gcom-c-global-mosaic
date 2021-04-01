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

#parallel --shuf --joblog getRSRF.sh.log ./getRSRF.sh {1}{2} ::: {00..17} ::: {00..35}
#for TILE in $(cat TileNum.lst); do
#    ./getLTOA.sh $TILE
#done
#parallel ./getLTOA.sh {} :::: TileNum.lst


#for TILE in $(cat TileNum.lst); do bash -x ./getLTOA.sh $TILE; done
for BUF in 04 05; do #3 5 7 9
    parallel ./composite.LTOA.sh {} $BUF :::: TileNum.lst
done

#tileComposite() {
#    export BUF=$1
#    export TILE=$2
#    make composite/LTOA/2000/20210328_${BUF}/composite.2000.${TILE}.20210328_${BUF}.mean.tif
#}
#export -f tileComposite

#parallel --bar tileComposite $BUF $TILE ::: 04 05 :::: TileNum.lst
#tileComposite 09 1224
