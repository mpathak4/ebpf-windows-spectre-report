<#
  sign-and-verify.ps1
  Signs artifacts using a PFX and verifies signature.
#>

param(
  [Parameter(Mandatory)][string]$PfxPath,
  [Parameter(Mandatory)][string]$PfxPassword,
  [string]$ArtifactsDir = "artifacts/bin"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path $PfxPath)) { throw "PFX not found" }

Get-ChildItem -Path $ArtifactsDir -Recurse -Include *.sys,*.dll,*.exe | ForEach-Object {
  $file = $_.FullName
  Write-Host "Signing $file"
  & signtool sign /fd SHA256 /a /f $PfxPath /p $PfxPassword /tr http://timestamp.digicert.com /td SHA256 $file
  & signtool verify /kp /v $file 2>&1 | Out-File "artifacts/sign-verify.log" -Append
}

Write-Host "Signing and verification complete. See artifacts/sign-verify.log" -ForegroundColor Green
 