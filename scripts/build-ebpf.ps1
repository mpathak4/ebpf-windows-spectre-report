<#
  build-ebpf.ps1
  Deterministic, auditable build of eBPF-for-Windows. Requires admin for some steps.
#>

param(
  [Parameter(Mandatory)][string]$OutDir,
  [switch]$Reproducible = $false,
  [switch]$Strict = $true,
  [switch]$DryRun = $false
)

if ($Strict) {
  Set-StrictMode -Version Latest
  $ErrorActionPreference = 'Stop'
}

$repo = "https://github.com/microsoft/ebpf-for-windows.git"
$srcRoot = Join-Path $env:TEMP 'ebpf-for-windows'
$buildLog = Join-Path (Get-Location) 'artifacts/logs/build-diagnostic.log'
New-Item -ItemType Directory -Path (Split-Path $buildLog) -Force | Out-Null

if ($DryRun) {
  Write-Host "[DRY RUN] Would clone and build in $srcRoot"
  exit 0
}

if (-not (Test-Path $srcRoot)) {
  git clone --recurse-submodules $repo $srcRoot
} else {
  Push-Location $srcRoot
  git fetch --all
  git reset --hard origin/main
  git submodule sync --recursive
  git submodule update --init --recursive
  Pop-Location
}

Push-Location $srcRoot

# Preflight checks
if (-not (Get-Command msbuild -ErrorAction SilentlyContinue)) { throw "msbuild not found" }
if (-not (Get-Command nuget -ErrorAction SilentlyContinue)) { throw "nuget not found" }

# Detect stampinf
$stamp = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -Recurse -Filter stampinf.exe -ErrorAction SilentlyContinue
if (-not $stamp) {
  Write-Host "WARNING: stampinf.exe not found. Some driver packaging targets will fail." -ForegroundColor Yellow
}

# Detect clang BPF capability
try {
  & clang -target bpf -c $null 2>$null
  $clangBpf = $true
} catch {
  $clangBpf = $false
  Write-Host "clang BPF target unavailable" -ForegroundColor Yellow
}

# Run CMake for externals
git submodule update --init --recursive

# Configure and build with deterministic flags
$msbuildFlags = "/m","/p:Deterministic=true","/p:ContinuousIntegrationBuild=true","/p:Configuration=Release","/p:Platform=x64"
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 2>&1 | Tee-Object -FilePath $buildLog
msbuild ".\ebpf-for-windows.sln" $msbuildFlags /fl /flp:logfile=$buildLog\;verbosity=diagnostic 2>&1 | Tee-Object -FilePath $buildLog

# Determine outputs
$outs = Get-ChildItem -Path . -Recurse -Include *.sys,*.dll,*.cat,*.exe -ErrorAction SilentlyContinue
if (-not $outs) {
  Write-Host "No build artifacts found. Review $buildLog" -ForegroundColor Red
  exit 1
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
foreach ($f in $outs) { Copy-Item $f.FullName -Destination $OutDir -Force }

Pop-Location
Write-Host "Build completed. Artifacts are in $OutDir" -ForegroundColor Green
