# LULESH 2.0（CPU + GPU 验证 + 基准测试）

本仓库包含 CUDA GPU 版本、用于 CPU/GPU 正确性验证的日志钩子，以及用于加速比与正确性图表的基准工具。

英文版说明: [README.md](README.md)

## 上游来源与溯源

位于 `lulesh-gpu/` 和 `lulesh-gpu-opt/` 的 GPU 实现以 git subtree 方式引入。上游来源与本地修复见 `UPSTREAM.md`。

## 我们在 GPU 上追加的改动（以及原因）

`lulesh-gpu-opt/` 下的 CUDA 实现是在上游基础上做的少量增强（详见 `UPSTREAM.md`）：

- 增加 GPU 端日志钩子与可配置的日志范围，便于对 CPU/GPU 结果做可重复的正确性对比。
- 增加多周期与子步骤日志选项，用于排查跨时间步的误差漂移并定位差异。
- 输出周期进度时遵循进度开关，保证基准日志更干净且可复现。
- 修正 `lulesh-gpu-opt/lulesh-cuda/lulesh.cu` 中的力累加顺序，并新增 hourglass 力日志，以便对照 CPU 结果验证修复。

**要点**
- GPU 版本位于 `lulesh-gpu-opt/lulesh-cuda`，生成 `lulesh_gpu`。
- 日志与对比工具位于 `benchmarks/`。
- 支持按周期输出 CSV 日志并进行容差比较的 CPU/GPU 正确性检查。
- 可根据采集结果生成加速比与正确性图表。

## 构建

CPU（串行/OpenMP，无 MPI）:
```
make -j CXX="g++ -DUSE_MPI=0"
```

GPU:
```
cd lulesh-gpu-opt/lulesh-cuda
nvcc -std=c++14 -O3 -arch=sm_89 \
  lulesh.cu lulesh-util.cu lulesh-viz.cu lulesh-init.cu \
  -o lulesh_gpu
```

## 日志与正确性验证

关键脚本:
- `benchmarks/compare_logs.py` 使用容差对比 CPU/GPU CSV 日志。
- `benchmarks/run_multi_compare.sh` 同时运行 CPU + GPU 并对比日志。
- `benchmarks/plot_correctness.py` 按周期汇总差异并生成图表。

示例（size 110, 10 cycles, stride 100, fields fx/fy/fz/e）:
```
LULESH_LOG_STRIDE=100 LOG_CYCLES=10 LOG_CYCLE_STRIDE=1 SIZE=110 ITERS=10 \
LOG_FIELDS=fx,fy,fz,e LOG_PRE=1 LOG_SUBSTEPS=0 \
benchmarks/run_multi_compare.sh

python3 benchmarks/plot_correctness.py --plot \
  --cpu benchmarks/logs-multi/cycles10-s1 \
  --gpu benchmarks/logs-gpu-multi/cycles10-s1 \
  --allow-missing
```

## 基准测试与加速比图表

加速比扫描脚本:
```
python3 benchmarks/bench_speedup.py --sizes 30,50,70,90,110 \
  --iterations 100 --cpu-threads 24 --plot
```

输出:
- `benchmarks/speedup.csv`
- `benchmarks/speedup.png`

## 记录结果（当前运行）

正确性（size 110 采样运行，10 cycles，stride 100，fields fx/fy/fz/e）:
- 最大绝对误差: 5.96e-08（cycle 6）
- 最大相对误差: 3.28e-13（cycle 4）
- 超出阈值计数: 0（所有 cycles）
- 图表: `benchmarks/correctness.png`

多周期正确性（20 cycles，stride 2）:
- 比较文件 1290 个，0 失败
- 日志: `benchmarks/logs-multi/cycles20-s2` 与
  `benchmarks/logs-gpu-multi/cycles20-s2`

加速比扫描（CPU 线程=24，iterations=100）:
- N=30: ~6.67x
- N=50: ~7.41x
- N=70: ~9.42x
- N=90: ~11.46x
- N=110: ~11.98x
- 图表: `benchmarks/speedup.png`

示例基线（size 110，iterations 100）:
- CPU: ~20.0s，FOM ~6592.5
- GPU: ~1.69s，FOM ~78971.2
- 加速比: ~11.8x

## 原始 README（译文）

```
这是 LULESH 2.0 的 README

更多信息（包括 LULESH 1.0）见 https://codesign.llnl.gov/lulesh.php

如有任何问题请联系：

Ian Karlin <karlin1@llnl.gov> 或
Rob Neely <neely4@llnl.gov>

若有值得报告的结果也请发送给 Ian Karlin <karlin1@llnl.gov>，我们仍在评估本代码的性能。

提供了 Makefile 和 CMake 构建系统。

*** 使用 CMake 构建 ***

创建构建目录并运行 cmake。例如：

  $ mkdir build; cd build; cmake -DCMAKE_BUILD_TYPE=Release -DMPI_CXX_COMPILER=`which mpicxx` ..

CMake 变量：

  CMAKE_BUILD_TYPE      "Debug"、"Release" 或 "RelWithDebInfo"

  CMAKE_CXX_COMPILER    C++ 编译器路径
  MPI_CXX_COMPILER      MPI C++ 编译器路径

  WITH_MPI=On|Off       构建 MPI（默认：On）
  WITH_OPENMP=On|Off    构建 OpenMP 支持（默认：On）
  WITH_SILO=On|Off      构建 SILO 支持（默认：Off）

  SILO_DIR              SILO 库路径（仅当 WITH_SILO 为 "On" 时需要）

*** LULESH 2.0 的重要变化 ***

功能拆分为多个文件
lulesh.cc - 大部分（全部？）计时逻辑
lulesh-comm.cc - MPI 功能
lulesh-init.cc - 初始化代码
lulesh-viz.cc  - 可视化选项支持
lulesh-util.cc - 非计时函数

新增了 "regions"（区域）概念。虽然每个区域仍是相同的理想气体材料，且仍只硬编码求解 Sedov 爆轰波问题，但区域带来两个重要特性，使该代理应用更具代表性：

LULESH 的四个例程现在按区域执行，使内存访问不再是单位步长

可以很容易引入人工负载不均衡，从而影响并行策略。
   * 负载均衡标志会改变区域分配。区域编号会按输入幂次调整分配概率。最可能的区域会随 MPI 进程 id 改变。
   * 成本标志会将约 45% 的区域 EOS 计算成本提高到指定倍数；其中 5% 的成本为输入倍数的 10 倍。

加入了 MPI 和 OpenMP，并合并为单一源码版本，可支持串行、仅 MPI、仅 OpenMP、以及 MPI+OpenMP 构建

当链接 silo 库时，增加了使用“简易并行 I/O”写出绘图文件的支持，可被 VisIt 读取。

默认启用可变时间步长计算（Courant 条件），会增加一次额外归约。同时根据解析方程为初始时间步长设定种子，以便缩放到任意规模。因此求解步骤数将不同于 LULESH 1.0。

默认域（网格）尺寸从 45^3 降到 30^3

提供命令行选项以支持多个测试用例而无需重新编译

在研究 LULESH 1.0 时发现的性能优化与代码清理

新增“性能指标”（Figure of Merit）计算（每微秒解决的单元数）并输出，以支持 2017 年 CORAL 采购中的 LULESH 2.0 使用

*** LULESH 2.1 的重要变化 ***

细微 bug 修复。
代码清理以统一变量命名、循环索引、内存分配/释放等。
在主类中增加析构函数以在退出时清理。


可能的未来 2.0 小版本更新（也可能出现其他改动）

* 不同的默认参数
* 细微性能改动与代码清理

未来版本 TODO
* 增加（真正）非结构化网格的读取器，可能仅支持串行
```
