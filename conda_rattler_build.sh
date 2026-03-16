#!/usr/bin/env bash
set -euo pipefail

# Paths
repo_root="$(pwd)"
pkgs_dir="${repo_root}/_work/packages"
recipe_dir="${repo_root}/conda-recipe"

# Create build env if it does not exist
if ! conda env list | awk '{print $1}' | grep -qx "rattler-build"; then
    conda create -y -n rattler-build -c conda-forge rattler-build
fi

# Activate env
eval "$(conda shell.bash hook)"
conda activate rattler-build

# Build
export CONDA_BLD_PATH="${pkgs_dir}"
rattler-build build \
    --recipe "${recipe_dir}" \
    --test skip