# Importe les skills depuis claude-skills/exported-for-ai vers les regles Cursor globales (.mdc).
# Conversion .md -> .mdc avec frontmatter (description, alwaysApply: false).
#
# Usage:
#   Depuis la racine du repo : .\scripts\sync-claude-skills-rules.ps1
#   Ou : .\scripts\sync-claude-skills-rules.ps1 -SourceDir "C:\path\to\claude-skills\exported-for-ai"
#
# Options:
#   -SourceDir <path>  Dossier source des skills .md (defaut: C:\Users\lapet\github-all\claude-skills\exported-for-ai)
#   -TargetDir <path>  Dossier cible des regles (defaut: $env:USERPROFILE\.cursor\rules)
#   -WhatIf           Affiche les actions sans ecrire

param(
    [string]$SourceDir = "C:\Users\lapet\github-all\claude-skills\exported-for-ai",
    [string]$TargetDir = $null,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

$SourceDir = [System.IO.Path]::GetFullPath($SourceDir)
$globalRulesDir = if ($TargetDir) { [System.IO.Path]::GetFullPath($TargetDir) } else { Join-Path $env:USERPROFILE ".cursor\rules" }

# ----- Verifications -----
if (-not (Test-Path $SourceDir)) {
    Write-Error "Dossier source introuvable: $SourceDir"
}

# ----- Cible -----
if (-not (Test-Path $globalRulesDir)) {
    if (-not $WhatIf) { New-Item -ItemType Directory -Path $globalRulesDir -Force | Out-Null }
    Write-Host "Cree: $globalRulesDir" -ForegroundColor Green
}

function Get-DescriptionFromMdContent {
    param([string]$Content, [string]$FileName)
    $firstLine = ($Content -split "`n")[0]
    if ($firstLine -match '^#\s+(.+)$') {
        $title = $Matches[1].Trim()
        # Escape quotes for YAML
        return $title.Replace('"', '\"')
    }
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    return $baseName.Replace('-', ' ').Replace('_', ' ')
}

function Convert-MdToMdc {
    param([string]$MdPath)
    $content = Get-Content -Path $MdPath -Raw -Encoding UTF8
    $fileName = [System.IO.Path]::GetFileName($MdPath)
    $description = Get-DescriptionFromMdContent -Content $content -FileName $fileName
    $safeDescription = $description -replace '[\r\n]', ' '
    $frontmatter = @"
---
description: "$safeDescription"
alwaysApply: false
---

"@
    return $frontmatter + $content
}

$mdFiles = @(Get-ChildItem -Path $SourceDir -Filter "*.md" -ErrorAction SilentlyContinue)
$total = $mdFiles.Count
Write-Host "$total skill(s) .md trouve(s) dans $SourceDir" -ForegroundColor Cyan
Write-Host ""

$copied = 0
$index = 0
foreach ($file in $mdFiles) {
    $index++
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $mdcName = $baseName + ".mdc"
    $dest = Join-Path $globalRulesDir $mdcName
    try {
        $mdcContent = Convert-MdToMdc -MdPath $file.FullName
        if (-not $WhatIf) {
            [System.IO.File]::WriteAllText($dest, $mdcContent, [System.Text.UTF8Encoding]::new($false))
        }
        Write-Host "  [$index/$total] OK $mdcName" -ForegroundColor Green
        $copied++
    } catch {
        Write-Warning "  [$index/$total] Ignore $($file.Name): $_"
    }
}

Write-Host ""
if ($WhatIf) {
    Write-Host "WhatIf: $copied regle(s) seraient copiees vers $globalRulesDir" -ForegroundColor Yellow
} else {
    Write-Host "Termine. $copied regle(s) importees depuis claude-skills vers $globalRulesDir" -ForegroundColor Cyan
    Write-Host "Elles s'appliquent a tous les projets dans Cursor (redemarrer Cursor si besoin)." -ForegroundColor Cyan
}
