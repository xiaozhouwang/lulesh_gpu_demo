#! /usr/bin/bash
#srun --mpi=pmi2 -n 9 --gres=gpu --partition=amd-shortq ./lulesh.out 18
#srun --mpi=pmi2 -n 9 --gres=gpu --partition=amd-shortq ./lulesh.out 189
#srun --mpi=pmi2 -n 8 --gres=gpu --partition=amd-shortq ./lulesh.out 192
#srun --mpi=pmi2 -n 8 --gres=gpu:xp:1 --partition=amd-longq ./lulesh.out 256 
srun --mpi=pmi2 -n 8 --gres=gpu --partition=amd-shortq ./lulesh.out $1
