# Copie les regles Cursor du projet vers le dossier global utilisateur (~/.cursor/rules/)
# pour qu'elles s'appliquent a TOUS les projets dans l'IDE.
# Lancer depuis la racine du repo : .\scripts\install-cursor-rules.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$sourceDir = Join-Path $root ".cursor\rules"
$globalDir = Join-Path $env:USERPROFILE ".cursor\rules"

if (-not (Test-Path $sourceDir)) {
    Write-Error "Dossier source introuvable: $sourceDir"
}

if (-not (Test-Path $globalDir)) {
    New-Item -ItemType Directory -Path $globalDir -Force | Out-Null
    Write-Host "Cree: $globalDir" -ForegroundColor Green
}

$copied = 0
Get-ChildItem -Path $sourceDir -Filter "*.mdc" | ForEach-Object {
    $dest = Join-Path $globalDir $_.Name
    Copy-Item -Path $_.FullName -Destination $dest -Force
    Write-Host "  OK $($_.Name)" -ForegroundColor Green
    $copied++
}

if ($copied -eq 0) {
    Write-Host "Aucun fichier .mdc dans .cursor/rules/" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Termine. $copied regle(s) copiee(s) vers $globalDir" -ForegroundColor Cyan
    Write-Host "Elles s'appliquent a tous les projets dans Cursor (redemarrer Cursor si besoin)." -ForegroundColor Cyan
}
