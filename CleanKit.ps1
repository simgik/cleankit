param(
  [string]$OutputRoot,
  [string]$UserProfile,
  [ValidateSet('pl', 'en')]
  [string]$Language = 'pl'
)

$ErrorActionPreference = 'Stop'
$appName = 'CleanKit'
$appVersion = '0.1.0'

$text = @{
  pl = @{
    ClosePrompt = 'Enter = zamknij'
    FileLabel = 'Plik'
    MissingScanner = 'Brak skanera'
    Intro1 = 'To narzedzie skanuje nieaktualne wpisy aplikacji, martwe skroty i uslugi.'
    Intro2 = 'Najpierw zrobi tylko raport. Usuwanie/przenoszenie bedzie dopiero po Twojej decyzji.'
    Admin1 = 'Administrator jest wymagany, zeby poprawnie sprzatac rejestr, skroty systemowe i uslugi.'
    Admin2 = 'Bez admina wynik moze byc tylko czesciowy.'
    AdminPrompt = 'Uruchomic teraz jako administrator? [1=tak / 2=nie]'
    Aborted = 'Przerwano.'
    Step1 = 'Krok 1: skan bez usuwania.'
    Step1Info = 'Sprawdzam nieaktualne wpisy Dodaj/usun programy, martwe skroty i martwe uslugi.'
    NoDelete = 'Na tym etapie nic nie jest kasowane.'
    Profile = 'Skanowany profil'
    SandboxWarning = 'UWAGA: to wyglada na profil sandboxa Codexa, nie Twoj normalny profil.'
    StartPrompt = 'Enter = start, Q = wyjscie'
    Decision = 'Decyzja:'
    Question = 'Mam usuwac/przenosic znalezione elementy czy tylko zrobic raport?'
    DeleteChoice = '[U] Usun/przenies znalezione elementy'
    ReportChoice = '[W] Wiedza/raport, bez zmian'
    QuitChoice = '[Q] Wyjscie'
    ChoicePrompt = 'Wybierz U/W/Q'
    CleanupStep = 'Krok 2: sprzatanie. Rejestr jest eksportowany do .reg, skroty ida do quarantine, uslugi sa usuwane.'
    VerifyStep = 'Krok 3: kontrolny skan po sprzataniu.'
    ReportOnly = 'Zostawiono tylko raport. Nic nie usuwalem.'
    Done = 'Gotowe.'
    OutputInfo = 'Log, raport i przeniesione pliki sa w folderze'
    QuarantineInfo = 'Folder quarantine zawiera backupi .reg i przeniesione skroty, jesli wybrales usuwanie.'
  }
  en = @{
    ClosePrompt = 'Enter = close'
    FileLabel = 'File'
    MissingScanner = 'Scanner not found'
    Intro1 = 'This tool scans stale application entries, broken shortcuts, and services.'
    Intro2 = 'It starts with a report only. Cleanup runs only after your decision.'
    Admin1 = 'Administrator rights are required to clean registry entries, system shortcuts, and services properly.'
    Admin2 = 'Without admin rights, results can be incomplete.'
    AdminPrompt = 'Run as administrator now? [1=yes / 2=no]'
    Aborted = 'Aborted.'
    Step1 = 'Step 1: scan without cleanup.'
    Step1Info = 'Checking stale Add/Remove Programs entries, broken shortcuts, and dead services.'
    NoDelete = 'Nothing is deleted at this stage.'
    Profile = 'Scanned profile'
    SandboxWarning = 'WARNING: this looks like the Codex sandbox profile, not your normal Windows profile.'
    StartPrompt = 'Enter = start, Q = quit'
    Decision = 'Decision:'
    Question = 'Should I remove/move found items or only create a report?'
    DeleteChoice = '[U] Remove/move found items'
    ReportChoice = '[W] Knowledge/report only, no changes'
    QuitChoice = '[Q] Quit'
    ChoicePrompt = 'Choose U/W/Q'
    CleanupStep = 'Step 2: cleanup. Registry entries are exported to .reg, shortcuts move to quarantine, services are removed.'
    VerifyStep = 'Step 3: verification scan after cleanup.'
    ReportOnly = 'Report only. Nothing was removed.'
    Done = 'Done.'
    OutputInfo = 'Log, report, and moved files are in'
    QuarantineInfo = 'The quarantine folder contains .reg backups and moved shortcuts if cleanup was selected.'
  }
}

$t = $text[$Language]

function Test-Admin {
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Wait-Exit {
  Write-Host ''
  Read-Host $t.ClosePrompt
}

function Show-File {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    Write-Host ''
    Write-Host "$($t.FileLabel): $Path"
    Write-Host ''
    Get-Content -LiteralPath $Path -Encoding UTF8 | Select-Object -First 80 | ForEach-Object {
      Write-Host $_
    }
  }
}

$desktop = [Environment]::GetFolderPath('Desktop')
if (-not $UserProfile) {
  $UserProfile = $env:USERPROFILE
}
if (-not $OutputRoot) {
  $OutputRoot = Join-Path $desktop 'CleanKit'
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scanner = Join-Path $scriptDir 'Scan-CleanKit.ps1'

if (-not (Test-Path -LiteralPath $scanner)) {
  Write-Host "$($t.MissingScanner): $scanner"
  Wait-Exit
  exit 1
}

if (-not (Test-Admin)) {
  Write-Host "$appName v$appVersion"
  Write-Host 'by simgik'
  Write-Host ''
  Write-Host $t.Intro1
  Write-Host $t.Intro2
  Write-Host ''
  Write-Host $t.Admin1
  Write-Host $t.Admin2
  $answer = Read-Host $t.AdminPrompt
  if ($answer -ne '1') {
    Write-Host $t.Aborted
    Wait-Exit
    exit 0
  }

  $args = @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', "`"$PSCommandPath`"",
    '-OutputRoot', "`"$OutputRoot`"",
    '-UserProfile', "`"$UserProfile`"",
    '-Language', $Language
  )
  Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $args
  exit 0
}

$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$runRoot = $OutputRoot
New-Item -ItemType Directory -Force -Path $runRoot | Out-Null

Clear-Host
Write-Host "$appName v$appVersion"
Write-Host 'by simgik'
Write-Host ''
Write-Host $t.Step1
Write-Host $t.Step1Info
Write-Host $t.NoDelete
Write-Host "$($t.Profile): $UserProfile"
if ($UserProfile -match 'CodexSandboxOnline') {
  Write-Host ''
  Write-Host $t.SandboxWarning
}
Write-Host ''
$start = Read-Host $t.StartPrompt
if ($start -match '^(q|Q)$') {
  Write-Host $t.Aborted
  Wait-Exit
  exit 0
}

$scanOutput = & $scanner -Base $runRoot -UserProfile $UserProfile -Language $Language
$scanOutput | Out-Host
$reportLine = $scanOutput | Where-Object { $_ -match '^(Zapisano|Saved): ' } | Select-Object -Last 1
$report = if ($reportLine) { $reportLine -replace '^(Zapisano|Saved): ', '' } else { $null }
Show-File -Path $report

Write-Host ''
Write-Host $t.Decision
Write-Host $t.Question
Write-Host $t.DeleteChoice
Write-Host $t.ReportChoice
Write-Host $t.QuitChoice
$decision = Read-Host $t.ChoicePrompt

if ($decision -match '^(u|U)$') {
  Write-Host ''
  Write-Host $t.CleanupStep
  & $scanner -Base $runRoot -UserProfile $UserProfile -Language $Language -Quarantine | Out-Host
  Write-Host ''
  Write-Host $t.VerifyStep
  & $scanner -Base $runRoot -UserProfile $UserProfile -Language $Language | Out-Host
} elseif ($decision -match '^(w|W)$') {
  Write-Host ''
  Write-Host $t.ReportOnly
} else {
  Write-Host ''
  Write-Host $t.Aborted
}

Write-Host ''
Write-Host $t.Done
Write-Host "$($t.OutputInfo): $runRoot"
Write-Host $t.QuarantineInfo
Wait-Exit
