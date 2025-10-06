FROM nvcr.io/nvidia/jax:23.08-py3

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
        python3 python3-dev python3-pip build-essential git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip

# Install tensorflow
RUN pip install tensorflow

# Install PyTorch 2.3.1 with CUDA 12.1 support
RUN pip install --no-cache-dir torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu121

# Install PyRosetta using the automated installer
# This is free for academic use
RUN pip install --no-cache-dir pyrosetta-installer && \
    python -c 'import pyrosetta_installer; pyrosetta_installer.install_pyrosetta()'

# Install Python dependencies for af2_initial_guess
RUN pip install --no-cache-dir \
    "numpy<2.0" \
    "biopython<1.80" \
    ml-collections==1.1.0 \
    ml_dtypes==0.5.3 \
    dm-haiku==0.0.10 \
    dm-tree==0.1.9 \
    absl-py==2.3.1 \
    scipy==1.15.3 \
    matplotlib==3.10.6 \
    mock==5.2.0

# Clone the dl_binder_design repository
RUN git clone https://github.com/nrbennet/dl_binder_design.git /app/dl_binder_design

# Clone ProteinMPNN into the mpnn_fr directory (required dependency)
RUN git clone https://github.com/dauparas/ProteinMPNN.git /app/dl_binder_design/mpnn_fr/ProteinMPNN

# Clone AlphaFold repository for the alphafold module
RUN git clone https://github.com/deepmind/alphafold.git /app/alphafold

# Install AlphaFold as a package
WORKDIR /app/alphafold
RUN pip install --no-cache-dir .

# Add af2_initial_guess to PYTHONPATH
ENV PYTHONPATH="/app/dl_binder_design/af2_initial_guess"
ENV PYTHONPATH="/app/dl_binder_design/mpnn_fr:${PYTHONPATH}"

# Add script directories to PATH for easy access
ENV PATH="/app/dl_binder_design/af2_initial_guess:/app/dl_binder_design/mpnn_fr:/app/dl_binder_design/include/silent_tools:${PATH}"


# Set working directory to af2_initial_guess
WORKDIR /app/dl_binder_design/af2_initial_guess

# Default command shows help
CMD ["python", "predict.py", "--help"]