# NVMe
Examples on using NVMe devices including example of Spectral library

In this tutorial we will use IOR benchmark to execute on GPFS and NVMe devices, while we will showcase the Spectral library

We will follow three examples, one executing IOR on GPFS, then on NVMe and the differences while using Spectral library


Reserving 2 nodes and executing IOR on GPFS

```
#!/bin/bash
#BSUB -P #ACCOUNT
#BSUB -J IOR
#BSUB -o gpfs_ior.o%J
#BSUB -e gpfs_ior.e%J
#BSUB -W 10
#BSUB -nnodes 2

jsrun -n 2 -r 1 -a 16 -c 16 ./bin/ior -t 16m -b 19200m -F -w -C -Q 1 -g -G 27 -k -e  -o ./output/ior_file_easy
```
