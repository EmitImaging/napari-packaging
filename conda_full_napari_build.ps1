# Repo root assumed = current directory (where build_installers.py is)
$repoRoot = (Resolve-Path ".").Path
$workDir  = Join-Path $repoRoot "_work"
$pkgsDir  = Join-Path $workDir "packages"
$envName  = "napari-packaging-installers"
$envFile  = Join-Path $repoRoot "environments/ci_installers_environment.yml"

# Ensure folders exist
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
New-Item -ItemType Directory -Force -Path $pkgsDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $pkgsDir "noarch") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $pkgsDir "win-64") | Out-Null

# Helper: convert a Windows path to a file:/// URL
function To-FileUrl([string] $path) {
    $p = (Resolve-Path $path).Path -replace '\\','/'
    if ($p -match '^[A-Za-z]:') { return "file:///$p" }
    return "file:///$p"
}

# --- Conda env management ---
try { conda deactivate | Out-Null } catch {}

# Check if env exists
$envExists = conda env list | Select-String -Pattern "^\s*$([regex]::Escape($envName))\s"
if (-not $envExists) {
    Write-Host "Creating conda env '$envName'"
    conda env create -n $envName --file $envFile
} else {
    Write-Host "Reusing existing conda env '$envName'"
}

conda activate $envName

# --- Index the local channel (required) ---
python -m conda_index $pkgsDir

# Build-time local channel URL (your _work/packages)
$pkgsUrl = To-FileUrl $pkgsDir

# IMPORTANT:
# The .condarc shipped INSIDE the installer must point to the bundle's internal pkgs dir,
# not your build machine path. Constructor expands ${PREFIX} at install-time.
$condarcPath = Join-Path $workDir "condarc.local.yml"
@"
channels:  #!final
  - file:///\${PREFIX}/pkgs
  - conda-forge
channel_priority: strict
show_channel_urls: true
"@ | Set-Content -Encoding UTF8 $condarcPath

# --- Build napari installers ---
# Use libmamba if you can (faster), but keep classic if you're debugging solver weirdness.
# If you hit OOM again, consider setting classic here or lowering specs.
$env:CONDA_SOLVER = "classic"

# CONDARC affects the build process (constructor/conda while solving).
# It's okay to use the generated file (it doesn't contain build-machine paths now).
$env:CONDARC = $condarcPath

# These are build-time knobs so constructor uses your local channel at build time.
$env:CONSTRUCTOR_USE_LOCAL = "1"
$env:CONSTRUCTOR_LOCAL_CHANNEL_URL = $pkgsUrl

# Kick off the build
python build_installers.py --location (Join-Path $repoRoot "..\napari")
