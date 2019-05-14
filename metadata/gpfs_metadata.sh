#!/bin/bash
#BSUB -P #Account
#BSUB -J GPFS_Metadata
#BSUB -o gpfs_metadata.o%J
#BSUB -W 2
#BSUB -nnodes 1

jsrun -n 2 -r 2 -a 1 -c 1 ./metadata
