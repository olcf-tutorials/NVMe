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
* We copy the data from NVMe, one process per compute node, so, per NVMe device and we save them in a fold  er with timestamp to avoid overwriting
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

## Results - Explanation

<img align="middle" src="https://github.com/olcf-tutorials/NVMe/blob/master/figures/summit_architecture.png?raw=true" width="55%">

From the Summit architecture figure above, we have two observations. Initially, the maximum bandwidth per node is 12-14 GB/s while the performance of the NVMe is 6 GB/s and 2.1 GB/s for read and write respectively. This means that GPFS performance can be faster for many cases. The maximum bandwidth for GPFS is 2.5TB/s and while we scale, the performance per node drops to adjust to the total limitations. Thus, up to around 1000-1100 compute nodes, could perform better on GPFS than NVMe in some cases.

We did repeat the experiments on 1100 compute nodes and we got the following results:
### GPFS

Max Write: 1289635.96 MiB/sec (1352281.32 MB/sec)

### NVMe
Max Write: 2210063.58 MiB/sec (2317419.63 MB/sec)

Now, the NVMe performance is 1.7 times faster than GPFS.

Of course, the results depend on the utilization of the system that moment and what the I/O workload and pattern is.

## Using Spectral

Spectral is a portable and transparent middleware library to enable use of the node-local burst buffers for accelerated application output on Summit. It is used to transfer files from node-local NVMe back to the parallel GPFS file system without the need of the user to interact during the job execution. Spectral runs on the isolated core of each reserved node, so it does not occupy resources and based on some parameters the user could define which folder to be copied to the GPFS. In order to use Spectral, the user has to do the following steps in the submission script:

* Request Spectral resources instead of NVMe
* Load spectrum module
* Declare the path where the files will be saved in the node-local NVMe (PERSIST_DIR)
* Declare the path on GPFS where the files will be copied (PFS_DIR)
* Execute the script spectral_wait.py when the application is finished in order to copy the files from NVMe to GPFS
* No need to copy the files manually, it is dome automatically.

```
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
```

Submit the script

```
bsub spectral_ior.sh
```

In this case the output folder is named nvme_output_XXXX where XXXX is timestamp. Inside in this folder a file called spectral.log is created where it demonstrates if a file is copied yet, for example:

```
Spectral Work ENQUEUE File : /gpfs/alpine/stf007/scratch/gmarkoma/bb_training/install/nvme_output_1557776904/ior_file_easy.00000026
Spectral Work DEQUEUE File : /gpfs/alpine/stf007/scratch/gmarkoma/bb_training/install/nvme_output_1557776904/ior_file_easy.00000004
Spectral Work DONE File : /gpfs/alpine/stf007/scratch/gmarkoma/bb_training/install/nvme_output_1557776904/ior_file_easy.00000004
```

Enqueue means that the file will be copied, Dequeue that the file is under transfer, and Done that the transfer finished.

In the output file you can information such as:

```
...
Enqueued:32 Dequeued:32 Done:31
Enqueued:32 Dequeued:32 Done:31
All files moved
```

The file are transferred without a manual copy from the user.

More information about Spectral library: https://www.olcf.ornl.gov/spectral-library/

For the cases that I/O occurs during the execution of an application, with Spectral the transfer happens concurrent with the computation, so the total time to solution is faster.
