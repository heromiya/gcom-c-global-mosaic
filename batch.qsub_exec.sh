#! /bin/bash

#for TILE in $(sort tile.lst | uniq | grep -v 0528 | grep -v 0529); do #0528 0529

#for TILE in  1617 0313 0619 1130; do #0528 0529 
#    qsub -g tgh-20IAV qsub_exec.sh $TILE
#done


#for HH in {0..35}; do
#    for VV in {0..17}; do
#	TILE=$(printf %02d%02d $VV $HH)
#	qsub -g tgh-20IAV qsub_exec.sh $TILE
#    done
#done
#if [ "$(grep $TILE RSRF.completed.lst)" = "" ]; then  ; fi
for TILE in 0113; do # 0117 0214 1513 1615 1618
     qsub -g tgh-20IAV qsub_exec.sh $TILE
done

#for PATH in 1..485; do
    
#    qsub -g tgh-20IAV qsub_exec.sh $TILE
#done

#qsub -g tgh-20IAV qsub_exec.NWLR.sh 03010
