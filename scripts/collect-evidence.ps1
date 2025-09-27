<#
  collect-evidence.ps1
  Packages logs, environment, and artifacts into evidence zip.
#>

param(
  [string]$OutZip = "artifacts/evidence.zip",
  [string]$BuildId = $(Get-Date -Format "yyyyMMdd-HHmmss")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$base = Get-Location
$artifactDirs = @("artifacts/env","artifacts/logs","artifacts/bin","artifacts/checksums")
foreach ($d in $artifactDirs) { New-Item -ItemType Directory -Path $d -Force | Out-Null }

# Generate sha256 manifest
Get-ChildItem -Path "artifacts/bin" -Recurse -File -ErrorAction SilentlyContinue |
  ForEach-Object { @{
      path = $_.FullName;
      sha256 = (Get-FileHash -Algorithm SHA256 $_.FullName).Hash
    }
  } | ConvertTo-Json -Depth 5 | Out-File artifacts/checksums/sha256-manifest.json -Encoding utf8

# Create provenance.json
$prov = @{
  build_id = $BuildId;
  timestamp = (Get-Date).ToString("o");
  user = $env:USERNAME;
  machine = $env:COMPUTERNAME;
  os = (Get-CimInstance Win32_OperatingSystem).Caption
}
$prov | ConvertTo-Json -Depth 5 | Out-File artifacts/env/provenance.json -Encoding utf8

# Create evidence zip
if (Test-Path $OutZip) { Remove-Item $OutZip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory((Get-Location).Path, $OutZip)

Write-Host "Evidence packaged to $OutZip" -ForegroundColor Green
