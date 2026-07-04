param(
  [string]$OutputDir = (Join-Path $PSScriptRoot '..\dist')
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$version = (Get-Content -Raw -Encoding UTF8 (Join-Path $root 'VERSION')).Trim()
$packageName = "CleanKit-$version"
$stage = Join-Path $env:TEMP $packageName
$resolvedOutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
$zip = Join-Path $resolvedOutputDir "$packageName.zip"

if (Test-Path -LiteralPath $stage) {
  Remove-Item -LiteralPath $stage -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $stage | Out-Null
New-Item -ItemType Directory -Force -Path $resolvedOutputDir | Out-Null

$include = @(
  'CleanKit.bat',
  'CleanKit-PL.bat',
  'CleanKit-EN.bat',
  'CleanKit.ps1',
  'Scan-CleanKit.ps1',
  'README.md',
  'LICENSE',
  'CHANGELOG.md',
  'SECURITY.md',
  'VERSION'
)

foreach ($item in $include) {
  Copy-Item -LiteralPath (Join-Path $root $item) -Destination $stage -Force
}

Copy-Item -LiteralPath (Join-Path $root 'docs') -Destination (Join-Path $stage 'docs') -Recurse -Force

if (Test-Path -LiteralPath $zip) {
  Remove-Item -LiteralPath $zip -Force
}

Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -Force
Write-Host "Created $zip"
