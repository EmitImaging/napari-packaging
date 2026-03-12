# Paths
$repoRoot = Resolve-Path .
$pkgsDir  = Join-Path $repoRoot "_work\packages"
$recipeDir = Join-Path $repoRoot "conda-recipe"

# Create / activate build env
if (-not (conda env list | Select-String "^rattler-build\s")) {
    conda create -y -n rattler-build -c conda-forge rattler-build
}

conda activate rattler-build

# Build
$env:CONDA_BLD_PATH = $pkgsDir
rattler-build build `
    --recipe $recipeDir `
    --test skip
