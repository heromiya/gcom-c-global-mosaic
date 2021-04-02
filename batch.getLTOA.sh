#parallel ./getLTOA.sh {} :::: TileNum.lst
#for TILE in $(cat TileNum.lst); do bash -x ./getLTOA.sh $TILE; done

for BUF in 04 05; do #3 5 7 9
    parallel ./composite.LTOA.sh {} $BUF :::: TileNum.lst
done

