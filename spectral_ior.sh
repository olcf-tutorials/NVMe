#!/bin/bash 
#BSUB -P #Account
#BSUB -J NVME_SPECTRAL_IOR
#BSUB -o nvme_spectral_ior.o%J
#BSUB -e nvme_spectral_ior.e%J
#BSUB -W 20
#BSUB -nnodes 2
#BSUB -alloc_flags spectral

module load spectral
export PERSIST_DIR=/mnt/bb/$USER
timest=$(date +%s)
mkdir nvme_output_$timest
export PFS_DIR=$PWD/nvme_output_$timest


jsrun -n 2 -r 1 -a 16 -c 16 ./bin/ior -t 16m -b 19200m -F -w -C -Q 1 -g -G 27 -k -e  -o /mnt/bb/$USER/ior_file_easy
jsrun -n 2 -r 1 ls -l /mnt/bb/$USER/
spectral_wait.py
