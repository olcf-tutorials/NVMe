#!/bin/bash
#BSUB -P #Account
#BSUB -J NVME_Metadata
#BSUB -o nvme_medatata.o%J
#BSUB -e nvme_medatata.e%J
#BSUB -W 2
#BSUB -nnodes 1
#BSUB -alloc_flags NVME


export BBPATH=/mnt/bb/$USER

jsrun -n 1 cp metadata ${BBPATH}
jsrun -n 2 -r 2 -a 1 -c 1 --chdir ${BBPATH} ./metadata
