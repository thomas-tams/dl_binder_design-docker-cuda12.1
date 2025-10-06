# =============================================================================
# Stage 1: Builder - Install dependencies and clone repositories
# =============================================================================
FROM nvcr.io/nvidia/jax:23.08-py3 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (minimal set for building)
RUN apt-get update && apt-get install -y \
        python3-dev \
        build-essential \
        git \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip

# Install PyRosetta using the automated installer (can be 1-2GB)
# This is free for academic use
# Split into two layers: installer, then actual PyRosetta package
RUN pip install --no-cache-dir pyrosetta-installer

RUN python -c 'import pyrosetta_installer; pyrosetta_installer.install_pyrosetta()'

# Install TensorFlow (typically 500MB-1GB)
RUN pip install --no-cache-dir tensorflow

# Install PyTorch 2.3.1 with CUDA 12.1 support
# Split into separate layers to avoid GHCR layer size limits (~10GB per layer)
# torch is ~2-3GB, torchvision ~1GB, torchaudio ~500MB
RUN pip install --no-cache-dir \
    torch==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu121

RUN pip install --no-cache-dir \
    torchvision==0.18.1 \
    --index-url https://download.pytorch.org/whl/cu121

RUN pip install --no-cache-dir \
    torchaudio==2.3.1 \
    --index-url https://download.pytorch.org/whl/cu121

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

# Clone repositories in builder stage
RUN git clone --depth 1 https://github.com/nrbennet/dl_binder_design.git /app/dl_binder_design && \
    git clone --depth 1 https://github.com/dauparas/ProteinMPNN.git /app/dl_binder_design/mpnn_fr/ProteinMPNN && \
    git clone --depth 1 https://github.com/deepmind/alphafold.git /app/alphafold

# Install AlphaFold as a package
WORKDIR /app/alphafold
RUN pip install --no-cache-dir .

# Clean up unnecessary files from git repositories to reduce size
RUN find /app -type d -name ".git" -exec rm -rf {} + 2>/dev/null || true && \
    find /app -type f -name "*.pyc" -delete && \
    find /app -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /app -type f -name "*.md" -delete 2>/dev/null || true

# =============================================================================
# Stage 2: Runtime - Minimal runtime image
# =============================================================================
FROM nvcr.io/nvidia/jax:23.08-py3 AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies (no build tools)
RUN apt-get update && apt-get install -y \
        python3 \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application files from builder
COPY --from=builder /app /app

# Set environment variables
ENV PYTHONPATH="/app/dl_binder_design/af2_initial_guess:/app/dl_binder_design/mpnn_fr:${PYTHONPATH}"
ENV PATH="/app/dl_binder_design/af2_initial_guess:/app/dl_binder_design/mpnn_fr:/app/dl_binder_design/include/silent_tools:${PATH}"

# Set working directory
WORKDIR /app/dl_binder_design/af2_initial_guess

# Default command shows help
CMD ["python", "predict.py", "--help"]