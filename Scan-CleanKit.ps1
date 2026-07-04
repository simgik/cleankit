param(
  [switch]$Quarantine,
  [string]$Base = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'CleanKit'),
  [string]$UserProfile = $env:USERPROFILE,
  [ValidateSet('pl', 'en')]
  [string]$Language = 'pl'
)

$ErrorActionPreference = 'Continue'
$appVersion = '0.1.0'

$base = $Base
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$out = Join-Path $base "CleanKit-report-$runId.txt"
$qRoot = Join-Path $base "quarantine-$runId"
$qRun = $qRoot
$log = Join-Path $base "CleanKit-actions-$runId.log"

$text = @{
  pl = @{
    Header = 'SPRAWDZIC'
    Generated = 'Wygenerowano'
    QuarantineMode = 'Tryb kwarantanny'
    Purpose = 'Cel: znalezione nieaktualne wpisy aplikacji bez uruchamiania programow.'
    None = '- brak'
    MissingInstall = 'brak InstallLocation'
    MissingIcon = 'brak DisplayIcon'
    UninstallBlock = 'NIEAKTUALNE WPISY DODAJ/USUN PROGRAMY'
    MissingTarget = 'brak target'
    CannotReadShortcut = 'nie mozna odczytac skrotu'
    ShortcutsBlock = 'MARTWE SKROTY START/DESKTOP'
    MissingImagePath = 'brak ImagePath'
    ServicesBlock = 'MARTWE USLUGI/STEROWNIKI'
    Saved = 'Zapisano'
    QuarantineLog = 'Kwarantanna/log'
  }
  en = @{
    Header = 'CHECK'
    Generated = 'Generated'
    QuarantineMode = 'Quarantine mode'
    Purpose = 'Purpose: found stale application entries without launching programs.'
    None = '- none'
    MissingInstall = 'missing InstallLocation'
    MissingIcon = 'missing DisplayIcon'
    UninstallBlock = 'STALE ADD/REMOVE PROGRAMS ENTRIES'
    MissingTarget = 'missing target'
    CannotReadShortcut = 'cannot read shortcut'
    ShortcutsBlock = 'BROKEN START/DESKTOP SHORTCUTS'
    MissingImagePath = 'missing ImagePath'
    ServicesBlock = 'DEAD SERVICES/DRIVERS'
    Saved = 'Saved'
    QuarantineLog = 'Quarantine/log'
  }
}

$t = $text[$Language]

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add($t.Header)
$lines.Add("CleanKit scan engine: $appVersion")
$lines.Add("$($t.Generated): $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("$($t.QuarantineMode): $Quarantine")
$lines.Add($t.Purpose)
$lines.Add('')

function Add-Block {
  param([string]$Title, [object[]]$Rows)
  $lines.Add($Title)
  if ($Rows -and $Rows.Count -gt 0) {
    foreach ($row in $Rows) { $lines.Add([string]$row) }
  } else {
    $lines.Add($t.None)
  }
  $lines.Add('')
}

function Write-ActionLog {
  param([string]$Text)
  $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  "$stamp $Text" | Add-Content -Encoding UTF8 $log
}

function Safe-RelativeName {
  param([string]$Path)
  return ($Path -replace '^[A-Za-z]:\\', '' -replace '[\\/:*?"<>|]', '_')
}

function Normalize-PathCandidate {
  param([string]$Value)
  if (-not $Value) { return $null }

  $text = [Environment]::ExpandEnvironmentVariables($Value.Trim())
  $text = $text.Replace('\??\', '')

  if ($text -match '^\s*"([^"]+)"') {
    return $matches[1]
  }

  if ($text -match '^([A-Za-z]:\\.*?\.(exe|dll|ico|sys))(\s|,|$)') {
    return $matches[1]
  }

  if ($text.Contains(',')) {
    $text = $text.Split(',')[0]
  }

  return $text.Trim('"').Trim()
}

function Export-RegKey {
  param([string]$PsPath, [string]$Name)
  if (-not $Quarantine) { return }
  New-Item -ItemType Directory -Force -Path (Join-Path $qRun 'registry') | Out-Null
  $regPath = $PsPath -replace '^Microsoft\.PowerShell\.Core\\Registry::', ''
  $file = Join-Path (Join-Path $qRun 'registry') ((Safe-RelativeName $Name) + '.reg')
  reg.exe export $regPath $file /y | Out-Null
  Write-ActionLog "EXPORTED REG $regPath -> $file"
}

function Move-ToQuarantine {
  param([string]$Path, [string]$Kind)
  if (-not $Quarantine) { return }
  $destDir = Join-Path $qRun $Kind
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null
  $dest = Join-Path $destDir (Safe-RelativeName $Path)
  try {
    Move-Item -LiteralPath $Path -Destination $dest -Force -ErrorAction Stop
    Write-ActionLog "MOVED $Path -> $dest"
    return
  } catch {
    Write-ActionLog "FAILED MOVE $Path -> $dest :: $($_.Exception.Message)"
  }

  try {
    Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
    Write-ActionLog "DELETED ORIGINAL $Path"
  } catch {
    Write-ActionLog "FAILED DELETE ORIGINAL $Path :: $($_.Exception.Message)"
  }
}

$uninstallKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$deadUninstall = foreach ($app in Get-ItemProperty $uninstallKeys -ErrorAction SilentlyContinue) {
  if (-not $app.DisplayName) { continue }
  $problems = @()

  $installLocation = Normalize-PathCandidate ([string]$app.InstallLocation)
  if ($installLocation -and $installLocation -match '^[A-Za-z]:\\' -and -not (Test-Path -LiteralPath $installLocation)) {
    $problems += "$($t.MissingInstall): $installLocation"
  }

  if ($app.DisplayIcon) {
    $icon = Normalize-PathCandidate ([string]$app.DisplayIcon)
    if ($icon -match '^[A-Za-z]:\\' -and -not (Test-Path -LiteralPath $icon)) {
      $problems += "$($t.MissingIcon): $icon"
    }
  }

  if ($problems.Count -gt 0) {
    if ($Quarantine) {
      try {
        Export-RegKey -PsPath $app.PSPath -Name $app.DisplayName
        Remove-Item -LiteralPath $app.PSPath -Recurse -Force -ErrorAction Stop
        Write-ActionLog "REMOVED REG $($app.DisplayName) :: $($app.PSPath)"
      } catch {
        Write-ActionLog "FAILED REG $($app.DisplayName) :: $($_.Exception.Message)"
      }
    }
    "- $($app.DisplayName) :: $($problems -join ' | ')"
  }
}

Add-Block $t.UninstallBlock @($deadUninstall)

$shortcutRoots = @(
  'C:\ProgramData\Microsoft\Windows\Start Menu',
  (Join-Path $UserProfile 'AppData\Roaming\Microsoft\Windows\Start Menu'),
  (Join-Path $UserProfile 'Desktop'),
  'C:\Users\Public\Desktop'
)

$shell = New-Object -ComObject WScript.Shell
$deadLinks = foreach ($root in $shortcutRoots) {
  if (-not (Test-Path -LiteralPath $root)) { continue }
  Get-ChildItem -LiteralPath $root -Filter '*.lnk' -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    try {
      $shortcutPath = $_.FullName
      $lnk = $shell.CreateShortcut($shortcutPath)
      $target = [string]$lnk.TargetPath
      if ($target -match '^[A-Za-z]:\\' -and -not (Test-Path -LiteralPath $target)) {
        if ($Quarantine) {
          try {
            Move-ToQuarantine -Path $shortcutPath -Kind 'shortcuts'
          } catch {
            Write-ActionLog "FAILED MOVE SHORTCUT $shortcutPath :: $($_.Exception.Message)"
          }
        }
        "- $shortcutPath :: $($t.MissingTarget): $target"
      }
    } catch {
      "- $($_.FullName) :: $($t.CannotReadShortcut)"
    }
  }
}

Add-Block $t.ShortcutsBlock @($deadLinks)

$deadServices = foreach ($svcKey in Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services' -ErrorAction SilentlyContinue) {
  $svc = Get-ItemProperty -LiteralPath $svcKey.PSPath -ErrorAction SilentlyContinue
  if (-not $svc.ImagePath) { continue }
  $img = Normalize-PathCandidate ([string]$svc.ImagePath)
  if ($img -match '^[A-Za-z]:\\' -and ($img.EndsWith('.exe') -or $img.EndsWith('.sys')) -and -not (Test-Path -LiteralPath $img)) {
    if ($Quarantine) {
      try {
        $scOut = sc.exe delete $svcKey.PSChildName 2>&1 | Out-String
        $scOut | Add-Content -Encoding UTF8 $log
        if ($LASTEXITCODE -eq 0) {
          Write-ActionLog "DELETED SERVICE $($svcKey.PSChildName) :: $img"
        } else {
          Write-ActionLog "FAILED SERVICE $($svcKey.PSChildName) :: exit=$LASTEXITCODE :: $($scOut.Trim())"
        }
      } catch {
        Write-ActionLog "FAILED SERVICE $($svcKey.PSChildName) :: $($_.Exception.Message)"
      }
    }
    "- $($svcKey.PSChildName) :: $($t.MissingImagePath): $img"
  }
}

Add-Block $t.ServicesBlock @($deadServices)

$lines | Set-Content -Encoding UTF8 $out
Write-Output "$($t.Saved): $out"
if ($Quarantine) {
  Write-Output "$($t.QuarantineLog): $qRoot"
}
