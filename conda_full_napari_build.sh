#!/usr/bin/env bash
set -euo pipefail

# Repo root assumed = current directory (where build_installers.py is)
repo_root="$(pwd)"
work_dir="${repo_root}/_work"
pkgs_dir="${work_dir}/packages"
env_name="napari-packaging-installers"
env_file="${repo_root}/environments/ci_installers_environment.yml"

# Ensure folders exist
mkdir -p "${work_dir}"
mkdir -p "${pkgs_dir}"
mkdir -p "${pkgs_dir}/noarch"
mkdir -p "${pkgs_dir}/osx-64"
mkdir -p "${pkgs_dir}/osx-arm64"

# Helper: convert a local path to a file:/// URL
to_file_url() {
    python - "$1" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve().as_uri())
PY
}

# --- Conda env management ---
set +e
eval "$(conda shell.bash hook)"
conda deactivate >/dev/null 2>&1
set -e

# Check if env exists
if ! conda env list | awk '{print $1}' | grep -qx "${env_name}"; then
    echo "Creating conda env '${env_name}'"
    conda env create -n "${env_name}" --file "${env_file}"
else
    echo "Reusing existing conda env '${env_name}'"
fi

conda activate "${env_name}"

# --- Index the local channel (required) ---
python -m conda_index "${pkgs_dir}"

# Build-time local channel URL (your _work/packages)
pkgs_url="$(to_file_url "${pkgs_dir}")"

# IMPORTANT:
# The .condarc shipped INSIDE the installer must point to the bundle's internal pkgs dir,
# not your build machine path. Constructor expands ${PREFIX} at install-time.
condarc_path="${work_dir}/condarc.local.yml"
cat > "${condarc_path}" <<'EOF'
channels:  #!final
  - file:///${PREFIX}/pkgs
  - conda-forge
channel_priority: strict
show_channel_urls: true
EOF


# --- Build napari installers ---
# Make sure pkgs dir exists
mkdir -p "${work_dir}/constructor-pkgs"
mkdir -p "${work_dir}/constructor-cache"

# libmamba (faster) or classic for solver issue
export CONDA_SOLVER="libmamba"

# CONDARC affects the build process (constructor/conda while solving).
# It's okay to use the generated file (it doesn't contain build-machine paths now).
export CONDARC="${condarc_path}"

# These are build-time knobs so constructor uses your local channel at build time.
export CONSTRUCTOR_USE_LOCAL="1"
export CONSTRUCTOR_LOCAL_CHANNEL_URL="${pkgs_url}"
export CONDA_PKGS_DIRS="${work_dir}/constructor-pkgs"
export CONSTRUCTOR_CACHE_DIR="${work_dir}/constructor-cache"

# Kick off the build
python build_installers.py --location "${repo_root}/../napari"