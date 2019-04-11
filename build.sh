#! /usr/bin/bash
make clean
srun --gres=gpu --partition=amd-shortq make
