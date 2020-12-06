#! /bin/bash

#for TILE in  1617  1130; do #
#    qsub -g tgh-20IAV qsub_exec.sh $TILE
#done


for HH in {0..35}; do
    for VV in {0..17}; do
	TILE=$(printf %02d%02d $VV $HH)
	echo "0619 0528 0529 0113 0117 0214 1513 1615 1618 0313" | grep $TILE
	if [ $? -ne 0 ]; then
	    qsub -g tgh-20IAV qsub_exec.sh $TILE
	fi
    done
done
#if [ "$(grep $TILE RSRF.completed.lst)" = "" ]; then  ; fi
#for TILE in 0619 0528 0529 0113 0117 0214 1513 1615 1618 0313; do
#     qsub -g tgh-20IAV qsub_exec.sh $TILE
#done
