# Synchronise les regles depuis cursor.directory (https://cursor.directory)
# vers le dossier global utilisateur (~/.cursor/rules/) pour les appliquer a tout l'IDE.
#
# Usage:
#   Depuis la racine du repo : .\scripts\sync-cursor-directory-rules.ps1
#   Ou depuis partout  : .\scripts\sync-cursor-directory-rules.ps1 -RepoRoot "C:\path\to\cursor-rules-automation"
#
# Options:
#   -RepoRoot <path>   Racine du repo cursor-rules-automation (contient scripts/lib/convert-directory-rules.cjs)
#   -TargetDir <path>  Dossier cible des regles (defaut: $env:USERPROFILE\.cursor\rules)
#   -NoClone          Ne pas cloner/mettre a jour le repo cursor.directory (utilise le cache existant)
#   -WhatIf           Affiche les actions sans ecrire

param(
    [string]$RepoRoot = $null,
    [string]$TargetDir = $null,
    [switch]$NoClone,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Racine du repo = dossier parent de scripts/
if (-not $RepoRoot) {
    $RepoRoot = Split-Path -Parent $PSScriptRoot
}
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

$globalRulesDir = if ($TargetDir) { $TargetDir } else { Join-Path $env:USERPROFILE ".cursor\rules" }
$cacheDir = Join-Path $env:LOCALAPPDATA "cursor-rules-automation"
$directoryRepoDir = Join-Path $cacheDir "cursor.directory"
$converterScript = Join-Path $RepoRoot "scripts\lib\convert-directory-rules.cjs"
$stagingDir = Join-Path $cacheDir "rules-staging"

# ----- Verifications -----
if (-not (Test-Path $converterScript)) {
    Write-Error "Script de conversion introuvable: $converterScript (RepoRoot=$RepoRoot)"
}

# ----- Clone ou mise a jour du repo cursor.directory -----
$repoUrl = "https://github.com/ggdayup/cursor.directory.git"
if (-not $NoClone) {
    if (Test-Path $directoryRepoDir) {
        Write-Host "Mise a jour du cache cursor.directory..." -ForegroundColor Cyan
        Push-Location $directoryRepoDir
        try {
            $errPref = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            & git fetch --depth 1 origin main 2>&1 | Out-Null
            & git reset --hard origin/main 2>&1 | Out-Null
            $ErrorActionPreference = $errPref
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "Clone de cursor.directory..." -ForegroundColor Cyan
        if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
        & git clone --depth 1 $repoUrl $directoryRepoDir
        if ($LASTEXITCODE -ne 0) { Write-Error "Clone a echoue." }
    }
} else {
    if (-not (Test-Path $directoryRepoDir)) {
        Write-Error "Cache absent. Relance sans -NoClone pour cloner le repo."
    }
}

# ----- Conversion TS -> .mdc -----
Write-Host "Conversion des regles en .mdc..." -ForegroundColor Cyan
if (-not (Test-Path $stagingDir)) { New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null }
& node $converterScript $directoryRepoDir $stagingDir
if ($LASTEXITCODE -ne 0) { Write-Error "Conversion a echoue." }

# ----- Copie vers le dossier global utilisateur -----
if (-not (Test-Path $globalRulesDir)) {
    if (-not $WhatIf) { New-Item -ItemType Directory -Path $globalRulesDir -Force | Out-Null }
    Write-Host "Cree: $globalRulesDir" -ForegroundColor Green
}

$copied = 0
Get-ChildItem -Path $stagingDir -Filter "*.mdc" -ErrorAction SilentlyContinue | ForEach-Object {
    $dest = Join-Path $globalRulesDir $_.Name
    if (-not $WhatIf) {
        Copy-Item -Path $_.FullName -Destination $dest -Force
    }
    Write-Host "  OK $($_.Name)" -ForegroundColor Green
    $copied++
}

Write-Host ""
if ($WhatIf) {
    Write-Host "WhatIf: $copied regle(s) seraient copiees vers $globalRulesDir" -ForegroundColor Yellow
} else {
    Write-Host "Termine. $copied regle(s) installees vers $globalRulesDir" -ForegroundColor Cyan
    Write-Host "Elles s'appliquent a tous les projets dans Cursor (redemarrer Cursor si besoin)." -ForegroundColor Cyan
}
