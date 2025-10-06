#!/bin/bash
# Example script to run dl-binder-design-docker-cuda12.1 prediction
# Usage: ./run_example.sh <pdb_directory>

set -e

# Check if input directory is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <pdb_directory>"
    echo "Example: $0 /path/to/pdb_files"
    exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR="./output_predict"
AF2_PARAMS="./test_params"

# Verify input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory does not exist: $INPUT_DIR"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Running dl-binder-design-docker-cuda12.1 predict.py on: $INPUT_DIR"
echo "Output will be saved to: $OUTPUT_DIR"

docker run --gpus all --rm \
  -v "$(realpath $INPUT_DIR)":/app/input \
  -v "$(realpath $OUTPUT_DIR)":/app/output \
  -v "$(realpath $AF2_PARAMS)":/app/dl_binder_design/af2_initial_guess/model_weights/params \
  ghcr.io/thomas-tams/dl_binder_design-docker-cuda12.1 \
  predict.py \
    -pdbdir /app/input \
    -recycle 3 \
    -outpdbdir /app/output

echo "Done! Check $OUTPUT_DIR for results."
