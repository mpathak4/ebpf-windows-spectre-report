<#
  bootstrap.ps1
  Validates and optionally guides installation of prerequisites for reproducible builds.
#>

param(
  [switch]$AutoFix = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Require-Tool($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Host "MISSING: $name - $hint" -ForegroundColor Red
    return $false
  } else {
    Write-Host "FOUND: $name" -ForegroundColor Green
    return $true
  }
}

Write-Host "Validating toolchain"

$checks = @(
  @{name='git'; hint='Install Git for Windows'},
  @{name='cmake'; hint='Install CMake 3.20+'},
  @{name='nuget'; hint='Place nuget.exe in C:\Tools\nuget and add to PATH'},
  @{name='msbuild'; hint='Install Visual Studio Build Tools with MSBuild'},
  @{name='cl'; hint='Install MSVC C++ toolset via Visual Studio'},
  @{name='signtool'; hint='Install Windows SDK or SignTool via Visual Studio'},
  @{name='candle.exe'; hint='Install WiX Toolset and ensure candle.exe in PATH'},
  @{name='light.exe'; hint='Install WiX Toolset and ensure light.exe in PATH'},
  @{name='vswhere'; hint='vswhere is in Visual Studio installer path'},
  @{name='clang'; hint='Install Clang/LLVM with BPF backend or prebuilt LLVM-BPF'}
)

$missing = @()
foreach ($c in $checks) {
  if (-not (Require-Tool $c.name $c.hint)) { $missing += $c }
}

if ($missing.Count -gt 0) {
  Write-Host "`nAction items:" -ForegroundColor Yellow
  foreach ($m in $missing) {
    Write-Host "- $($m.name): $($m.hint)"
  }
  if ($AutoFix) {
    Write-Host "AutoFix requested. Attempting safe fixes." -ForegroundColor Cyan
    if ($missing | Where-Object { $_.name -eq 'nuget' }) {
      New-Item -ItemType Directory -Path 'C:\Tools\nuget' -Force | Out-Null
      Write-Host "Created C:\Tools\nuget. Place nuget.exe there and re-run." -ForegroundColor Yellow
    }
  }
  exit 2
}

Write-Host "All required tools detected" -ForegroundColor Green

# Capture environment provenance
$envOut = Join-Path -Path (Get-Location) -ChildPath "artifacts/env"
New-Item -ItemType Directory -Path $envOut -Force | Out-Null

msbuild -version 2>&1 | Out-File (Join-Path $envOut 'msbuild.txt') -Encoding utf8
cl.exe 2>&1 | Out-File (Join-Path $envOut 'cl.txt') -Encoding utf8
cmake --version 2>&1 | Out-File (Join-Path $envOut 'cmake.txt') -Encoding utf8
nuget help 2>&1 | Out-File (Join-Path $envOut 'nuget.txt') -Encoding utf8
clang --version 2>&1 | Out-File (Join-Path $envOut 'clang.txt') -Encoding utf8
vswhere -format json 2>&1 | Out-File (Join-Path $envOut 'vswhere.json') -Encoding utf8

Write-Host "Provenance captured at $envOut" -ForegroundColor Green
