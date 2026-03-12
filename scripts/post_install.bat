@echo on
setlocal EnableExtensions EnableDelayedExpansion

REM post_install.bat is extracted under <install_root>\pkgs\
REM The install root is the parent of that folder.
for %%I in ("%~dp0..") do set "ROOT=%%~fI"

echo SCRIPT DIR = %~dp0
echo ROOT = %ROOT%

set "PY=%ROOT%\python.exe"
if not exist "%PY%" (
  echo ERROR: python.exe not found at "%PY%"
  exit /b 1
)

REM Critical: add the bundled env DLL dirs first so numpy/Qt/etc don't explode
set "PATH=%ROOT%\Library\bin;%ROOT%\Scripts;%ROOT%;%PATH%"

"%PY%" -m pip install --no-input --upgrade pip
if errorlevel 1 exit /b 1

"%PY%" -m pip install --no-input napari-imagecodecs napari-itk-io cft-zarr
if errorlevel 1 exit /b 1

echo Done pip installs.
endlocal
exit /b 0