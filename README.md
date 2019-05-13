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

submit the job script:
```
bsub gpfs_ior.sh
```

## Results

You can open the output/error files if you want or just execute the following on the output file, where XXXXX is your job ID:

```
$ grep Max gpfs_ior.oXXXXX | head -n 1
Max Write: 25178.81 MiB/sec (26401.90 MB/sec)
```

In this result from Summit, we could achieve 26401 MB/s from two compute nodes 

## Reserving 2 nodes and executing IOR on NVMe (nvme_ior.sh)

Edit the file and declare your account
Here there are some changes:
* You need to declare the alloc_flags NVME
* If you want to copy either into/from NVME, you need to use the jsrun command, it is not available from the login node otherwise.
* We copy the data from NVMe, one process per compute node, so, per NVMe device and we save them in a fodler with timestamp to avoid overwriting
* Delete your data to avoid fill in your space.

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

submit the job script:
```
bsub nvme_ior.sh
```

## Results

You can open the output/error files if you want or just execute the following on the output file, where XXXXX is your job ID:

```
grep Max nvme_ior.oXXXXX | head -n 1
Max Write: 4124.85 MiB/sec (4325.22 MB/sec)
```
In this case the NVMe performance fro two node sis 4325 MB/s. One question that raises, is why NVMe performance is worse than GPFS?

## Explanation
