# Quick Start Guide

## Prerequisites

1. Install Docker
2. Install NVIDIA Container Toolkit
3. Have an NVIDIA GPU with CUDA support

## Building the Image

```bash
cd af2_initial_guess-docker-cuda12.1
docker build -t af2_initial_guess-docker-cuda12.1 .
```

**Note**: Building will take 30-60 minutes due to PyRosetta installation.

## Running Your First Prediction

### 1. Prepare Input

Create a directory with PDB files:

```bash
mkdir -p input_pdbs
# Place your PDB files in input_pdbs/
```

### 2. Run Prediction

**Option A: Using the helper script**
```bash
./run_example.sh input_pdbs
```

**Option B: Direct Docker command**
```bash
docker run --gpus all \
  -v $(pwd)/input_pdbs:/app/input \
  -v $(pwd)/output:/app/output \
  af2_initial_guess-docker-cuda12.1 \
  python predict.py \
    -pdbdir /app/input \
    -recycle 3 \
    -out /app/output
```

### 3. Check Results

Results will be in the `output` directory.

## Common Issues

### GPU Not Found

Verify GPU access:
```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-runtime-ubuntu22.04 nvidia-smi
```

### CUDA Unknown Error

Reboot your system or enable GPU persistence:
```bash
sudo nvidia-smi -pm 1
```

### AlphaFold Parameters Missing

If you need AlphaFold model parameters:
1. Download from [AlphaFold GitHub](https://github.com/deepmind/alphafold)
2. Mount the params directory:
```bash
docker run --gpus all \
  -v $(pwd)/alphafold_params:/app/alphafold_params \
  -v $(pwd)/input_pdbs:/app/input \
  -v $(pwd)/output:/app/output \
  af2_initial_guess-docker-cuda12.1 \
  python predict.py -pdbdir /app/input -out /app/output
```

## Next Steps

- Read the full [README.md](README.md) for advanced usage
- Check [predict.py options](https://github.com/nrbennet/dl_binder_design/tree/main/af2_initial_guess) for more parameters
- Explore the dl_binder_design toolkit for complete binder design workflows

## Getting Help

View available options:
```bash
docker run --rm af2_initial_guess-docker-cuda12.1 python predict.py --help
```

Interactive shell for debugging:
```bash
docker run --gpus all -it --entrypoint /bin/bash af2_initial_guess-docker-cuda12.1
```
