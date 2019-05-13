# NVMe

Each compute node on Summit has a Non-Volatile Memory (NVMe) storage device, colloquially known as a "Burst Buffer" with theoretical performance peak of 2.1 GB/s for writing and 6.0 GB/s for reading. Users will have access to an 1600 GB partition of each NVMe. The NVMes could be used to reduce the time that applications wait for I/O. Using an SSD drive per compute node, the burst buffer will be used to transfers data to or from the drive before the application reads a file or after it writes a file. The result will be that the application benefits from native SSD performance for a portion of its I/O requests. 


<img align="middle" src="https://github.com/olcf-tutorials/NVMe/blob/master/figures/nvme_local.png?raw=true" width="55%">


More information: https://www.olcf.ornl.gov/for-users/system-user-guides/summit/summit-user-guide/#burst-buffer

In this tutorial we will use IOR benchmark to execute on GPFS and NVMe devices, while we will showcase the Spectral library

We will follow three examples, one executing IOR on GPFS, then on NVMe and the differences while using Spectral library. In all the cases we do write one file per MPI process.


## Compiling IOR

```
module load gcc
git clone https://github.com/hpc/ior.git
cd ior
./bootstrap
./configure --prefix=/declare_path/
make install
```

## Go to the IOR installation path
Select below the prefix from the configure command above


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

## Results from GPFS

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
* The copy from NVme, takes time, that's why the time limit for the NVMe job could be longer than the GPFS job in some cases. 
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

## Results from NVMe

You can open the output/error files if you want or just execute the following on the output file, where XXXXX is your job ID:

```
grep Max nvme_ior.oXXXXX | head -n 1
Max Write: 4124.85 MiB/sec (4325.22 MB/sec)
```
In this case the NVMe performance for two nodes is 4325 MB/s, 6.5 times slower than the GPFS. One question that raises, is why NVMe performance is worse than GPFS?

## Explanation

<img align="middle" src="https://github.com/olcf-tutorials/NVMe/blob/master/figures/summit_architecture.png?raw=true" width="55%">

From the Summit architecture figure above, we have two observations. Initially, the maximum bandwidth per node is 12-14 GB/s while the performance of the NVMe is 6 GB/s and 2.1 GB/s for read and write respectively. This means that GPFS performance can be faster for many cases. The maximum bandwidth for GPFS is 2.5TB/s and while we scale, the performance per node drops to adjust to the total limitations. Thus, up to around 1000-1100 compute nodes, could perform better on GPFS than NVMe in some cases.

We did repeat the experiments on 1100 compute nodes and we got the following results:
### GPFS

Max Write: 1289635.96 MiB/sec (1352281.32 MB/sec)

### NVMe
Max Write: 2210063.58 MiB/sec (2317419.63 MB/sec)

Now, the NVMe performance is 1.7 times faster than GPFS.

Of course, the results depend on the utilization of the system that moment and what the I/O workload and pattern is.

