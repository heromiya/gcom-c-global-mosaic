#! /bin/bash

for TILE in $(cat GCOM-C/TileNum.lst); do
    qsub -g tgh-20IAV qsub_exec.sh $TILE
done

#echo "0619 0528 0529 0113 0117 0214 1513 1615 1618 0313" | grep $TILE
#if [ "$(grep $TILE RSRF.completed.lst)" = "" ]; then  ; fi
#for TILE in 0619 0528 0529 0113 0117 0214 1513 1615 1618 0313; do
#     qsub -g tgh-20IAV qsub_exec.sh $TILE
#done
