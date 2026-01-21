# Upstream Sources and Local Changes

This repository vendors two GPU implementations as git subtrees for a
self-contained history. The subtrees live under `lulesh-gpu/` and
`lulesh-gpu-opt/`.
Commit IDs below refer to the subtree history recorded in this repo.

## Upstream Sources

- `lulesh-gpu`: https://github.com/maxbaird/luleshMultiGPU_MPI.git
  - Imported at commit `00d5767` ("Updated Makefile to use cuda 10.0").
- `lulesh-gpu-opt`: https://github.com/yehonatan123f/LULESH-GPU-Optimization.git
  - Imported at commit `1499f37` ("Initial commit").

## Local Changes for Correctness and Validation

The following commits are local additions on top of the `lulesh-gpu-opt`
upstream history (commit IDs are from this repo's subtree history):

- `67503d8` feat: add logging hooks for GPU verification
- `d7a52fe` chore: honor progress flag for cycle output
- `defe43a` feat: support multi-cycle logging
- `14eb69b` feat: extend logging controls and substep snapshots
- `4287a3c` fix: correct force accumulation and log hourglass forces

Correctness fix detail:
- `4287a3c` swaps accumulation behavior between `acc_final_force` and
  `collect_final_force` in `lulesh-gpu-opt/lulesh-cuda/lulesh.cu`, and adds
  hourglass-force logging for validation.
