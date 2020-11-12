#! /bin/bash
#$(sort tile.lst | uniq | grep -v 0528 | grep -v 0529)
for TILE in 0528 0529; do
    qsub -g tgh-20IAV qsub_exec.sh $TILE
done
