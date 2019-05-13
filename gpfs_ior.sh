#!/bin/bash
#BSUB -P #ACCOUNT
#BSUB -J GPFS_IOR
#BSUB -o gpfs_ior.o%J
#BSUB -e gpfs_ior.e%J
#BSUB -W 10
#BSUB -nnodes 2


jsrun -n 2 -r 1 -a 16 -c 16 ./bin/ior -t 16m -b 19200m -F -g -G 27 -k -e  -o ./output/ior_file_easy 
