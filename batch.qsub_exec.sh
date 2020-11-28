#! /bin/bash

#for TILE in $(sort tile.lst | uniq | grep -v 0528 | grep -v 0529); do #0528 0529
#    qsub -g tgh-20IAV qsub_exec.sh $TILE
#done

#for PATH in 1..485; do
    
#    qsub -g tgh-20IAV qsub_exec.sh $TILE
#done

qsub -g tgh-20IAV qsub_exec.NWLR.sh 03010
