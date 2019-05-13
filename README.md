# NVMe
Examples on using NVMe devices including example of Spectral library

In this tutorial we will use IOR benchmark to execute on GPFS and NVMe devices, while we will showcase the Spectral library

We will follow three examples, one executing IOR on GPFS, then on NVMe and the differences while using Spectral library


## Compiling iOR

```
module load gcc
git clone https://github.com/hpc/ior.git
cd ior
./bootstrap
./configure --prefix=/declare_path/
make install
```

## Go to the IOR installation path
Select below the prefix fromt he configure command above


```
cd /declare_path/
```

## Reserving 2 nodes and executing IOR on GPFS (gpfs_ior.sh)

Edit the file and declare your account

```
#!/bin/bash
#BSUB -P #ACCOUNT
#BSUB -J GPFS_IOR
#BSUB -o gpfs_ior.o%J
#BSUB -e gpfs_ior.e%J
#BSUB -W 10
#BSUB -nnodes 2

jsrun -n 2 -r 1 -a 16 -c 16 ./bin/ior -t 16m -b 19200m -F -w -C -Q 1 -g -G 27 -k -e  -o ./output/ior_file_easy
```

## Reserving 2 nodes and executing IOR on NVMe (nvme_ior.sh)

Edit the file and declare your account

```
#!/bin/bash 
#BSUB -P #ACCOUNT
#BSUB -J NVME_IOR
#BSUB -o nvme_ior.o%J
#BSUB -e nvme_ior.e%J
#BSUB -W 20
#BSUB -nnodes 2
#BSUB -alloc_flags NVME

jsrun -n 2 -r 1 -a 16 -c 16 ./bin/ior -t 16m -b 19200m -F -w -C -Q 1 -g -G 27 -k -e  -o /mnt/bb/$USER/ior_file_easy
timest=$(date +%s)
mkdir nvme_output_$timest
jsrun -n 2 -r 1 ls -l /mnt/bb/$USER/
jsrun -n 2 -r 1 cp -r /mnt/bb/$USER/ ./nvme_output_$timest/
```
