# AlphaFold2 Initial Guess Docker Image (CUDA 12.1)

Optimized Docker image for af2_initial_guess from the dl_binder_design toolkit with NVIDIA CUDA 12.1 support, pre-configured with AlphaFold2, PyRosetta, and all dependencies.

## Features

- **Base Image**: NVIDIA CUDA 12.1 with cuDNN 8 runtime on Ubuntu 22.04
- **Python**: 3.11 (matching af2_binder_design.yml specifications)
- **AlphaFold2**: DeepMind's AlphaFold inference pipeline
- **PyRosetta**: Automated installation via pyrosetta-installer (academic use)
- **JAX**: 0.4.20 with CUDA 12 support for GPU acceleration
- **TensorFlow**: For AlphaFold model inference
- **Pre-installed**: dl_binder_design repository with af2_initial_guess tools

## What is af2_initial_guess?

af2_initial_guess is part of the dl_binder_design toolkit developed by the Baker Lab. It uses AlphaFold2 to generate initial structure predictions for protein binder design workflows. This tool combines:
- AlphaFold2 structure prediction
- PyRosetta for structure manipulation
- Custom utilities for binder design preparation

## Requirements

- Docker with NVIDIA GPU support
- NVIDIA Container Toolkit installed on host
- NVIDIA GPU with CUDA capability
- NVIDIA Driver version 450.80.02 or higher

## Installation

### Build Locally

```bash
git clone <your-repo-url>
cd af2_initial_guess-docker-cuda12.1
docker build -t af2_initial_guess-docker-cuda12.1 .
```

**Note**: Building may take 30-60 minutes due to PyRosetta installation.

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/<your-username>/af2_initial_guess-docker-cuda12.1:latest
```

### Test CUDA Availability

```bash
docker run --rm --gpus all af2_initial_guess-docker-cuda12.1 python -c "import jax; print(f'JAX devices: {jax.devices()}')"
```

## Usage

### Basic Structure Prediction

Run af2_initial_guess on a PDB file:

```bash
docker run --gpus all \
  -v $(pwd)/input:/app/input \
  -v $(pwd)/output:/app/output \
  af2_initial_guess-docker-cuda12.1 \
  python predict.py \
    -pdbdir /app/input \
    -out /app/output
```

### With Specific Recycling Iterations

```bash
docker run --gpus all \
  -v $(pwd)/input:/app/input \
  -v $(pwd)/output:/app/output \
  af2_initial_guess-docker-cuda12.1 \
  python predict.py \
    -pdbdir /app/input \
    -recycle 5 \
    -out /app/output
```

### Force Monomer Prediction

```bash
docker run --gpus all \
  -v $(pwd)/input:/app/input \
  -v $(pwd)/output:/app/output \
  af2_initial_guess-docker-cuda12.1 \
  python predict.py \
    -pdbdir /app/input \
    -force_monomer \
    -out /app/output
```

### Interactive Shell

Access the container interactively for custom workflows:

```bash
docker run --gpus all -it \
  -v $(pwd)/data:/app/data \
  --entrypoint /bin/bash \
  af2_initial_guess-docker-cuda12.1
```

Inside the container:
```bash
cd /app/dl_binder_design/af2_initial_guess
python predict.py -h
```

### Using the Helper Script

The repository includes a convenient helper script:

```bash
./run_example.sh /path/to/pdb_directory
```

## Common Parameters

- `-pdbdir`: Directory containing PDB files to process
- `-silent`: Silent file input (Rosetta format)
- `-recycle`: Number of AF2 recycling iterations (default: 3)
- `-force_monomer`: Force prediction as a monomer
- `-max_amide_dist`: Maximum distance between amide bond atoms
- `-debug`: Enable detailed error reporting
- `-out`: Output directory for predictions

## Input Files

The tool accepts:
- **PDB files**: Individual protein structures or directories of PDB files
- **Silent files**: Rosetta silent format files

## Output Files

Generates:
- **Predicted structures**: PDB files with AF2 predictions
- **Silent files**: If input was in silent format
- **Scores and metrics**: Structure quality and prediction confidence

## Environment Details

- **Python Version**: 3.11
- **AlphaFold Location**: `/app/alphafold`
- **dl_binder_design Location**: `/app/dl_binder_design`
- **Working Directory**: `/app/dl_binder_design/af2_initial_guess`

## Use in Nextflow

```groovy
process AF2_INITIAL_GUESS {
    container 'ghcr.io/<your-username>/af2_initial_guess-docker-cuda12.1:latest'
    containerOptions '--gpus all'

    input:
    tuple val(meta), path(pdb_dir)

    output:
    tuple val(meta), path("${meta.id}_af2/*.pdb"), emit: predictions
    tuple val(meta), path("${meta.id}_af2/*.silent"), emit: silent, optional: true

    script:
    """
    mkdir -p ${meta.id}_af2
    python /app/dl_binder_design/af2_initial_guess/predict.py \
      -pdbdir ${pdb_dir} \
      -recycle 3 \
      -out ${meta.id}_af2
    """
}
```

## Use with Apptainer/Singularity

```bash
# Build from local Docker image
apptainer build af2_initial_guess.sif docker-daemon://af2_initial_guess-docker-cuda12.1:latest

# Run prediction
apptainer run --nv af2_initial_guess.sif \
  python predict.py \
  -pdbdir input_pdbs \
  -out output
```

## Troubleshooting

### CUDA Unknown Error

If you encounter "CUDA unknown error" when running the container:

1. **Reboot your system** - GPU state issues from suspend/resume can cause this
2. **Enable persistence mode**: `sudo nvidia-smi -pm 1`
3. **Verify GPU is accessible**: `docker run --rm --gpus all nvidia/cuda:12.1.0-runtime-ubuntu22.04 nvidia-smi`

### GPU Not Detected

Ensure NVIDIA Container Toolkit is properly installed:

```bash
# Install NVIDIA Container Toolkit (Ubuntu/Debian)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### PyRosetta Import Errors

If you encounter PyRosetta import errors:

1. Verify PyRosetta was installed during build: `docker run --rm af2_initial_guess-docker-cuda12.1 python -c "import pyrosetta"`
2. For commercial use, you'll need to rebuild with proper licensing credentials
3. Check that the build completed successfully without PyRosetta installation failures

### Out of Memory Errors

For large proteins or complexes:
1. Use a GPU with more VRAM (minimum 8GB recommended)
2. Reduce number of recycling iterations with `-recycle 1`
3. Process structures individually rather than in batch

### AlphaFold Model Parameters

**Important**: This Docker image does NOT include AlphaFold model parameters (~4GB). You'll need to:

1. Download model parameters from DeepMind
2. Mount them into the container:
```bash
docker run --gpus all \
  -v $(pwd)/alphafold_params:/app/alphafold_params \
  -v $(pwd)/input:/app/input \
  -v $(pwd)/output:/app/output \
  af2_initial_guess-docker-cuda12.1 \
  python predict.py -pdbdir /app/input -out /app/output
```

## Architecture Improvements

This optimized version provides several improvements:

- **CUDA 12.1 Native**: Direct NVIDIA CUDA base for optimal GPU compatibility
- **Python 3.11**: Latest stable Python matching dl_binder_design specs
- **JAX GPU Acceleration**: CUDA-optimized JAX for faster AF2 inference
- **Automated PyRosetta**: One-step installation via pyrosetta-installer
- **No Conda Overhead**: Pure pip installation for smaller images and faster builds
- **Integrated AlphaFold**: Pre-installed and configured AlphaFold module

## License

This Docker image packages multiple software components with different licenses:

- **AlphaFold**: Apache 2.0 (code), CC BY-NC 4.0 (model parameters - non-commercial)
- **PyRosetta**: Academic license (free for academic use, commercial use requires license)
- **dl_binder_design**: Check the repository for license information

**Important**: This image is intended for academic and non-commercial use. Commercial use requires appropriate licenses for PyRosetta and AlphaFold model parameters.

## References

- [dl_binder_design GitHub](https://github.com/nrbennet/dl_binder_design)
- [AlphaFold GitHub](https://github.com/deepmind/alphafold)
- [PyRosetta](https://www.pyrosetta.org/)
- [JAX Documentation](https://jax.readthedocs.io/)

## Citation

If you use this tool, please cite:

**AlphaFold2**:
```
@Article{AlphaFold2021,
  author  = {Jumper, John et al.},
  journal = {Nature},
  title   = {Highly accurate protein structure prediction with AlphaFold},
  year    = {2021},
  doi     = {10.1038/s41586-021-03819-2}
}
```

**PyRosetta** and **dl_binder_design**: Check respective repositories for citation information.
# dl_binder_design-docker-cuda12.1
