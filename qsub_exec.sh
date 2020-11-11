#!/bin/bash

#mkdir -p qsub.log.d
#LOG=qsub.log.d/qsub_exec.`date +%s`.log
#qsub -g tgh-20IAV qsub_exec.sh
#$ -cwd
#$ -o qsub_exec.log
#$ -l q_core=1
#$ -l h_rt=00:10:00
#$ -N GCOM-C
#$ -j y
#$ -m abe
#$ -M heromiya@hotmail.com

#rm -f qsub.log.d/qsub_exec.sh.log
#rm -f $LOG

#echo "### $(date +'%F_%T')" >> $LOG
. /etc/profile.d/modules.sh
#module load intel cuda/9.0.176 nccl/2.4.2 cudnn/7.4 tensorflow/1.12.0
. /home/7/17IA0902/miniconda3/etc/profile.d/conda.sh

export PATH=/home/7/17IA0902/miniconda3/bin/:$PATH
#export PATH=/home/7/17IA0902/apps/bin:$PATH
#export LD_LIBRARY_PATH=/home/7/17IA0902/apps/lib
export PROJ_LIB=/gs/hs0/tgh-20IAV/miyazaki/proj

bash -x getRSRF.sh $1
