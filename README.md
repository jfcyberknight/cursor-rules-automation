# cursor-rules-automation

Scripts pour automatiser l’installation et la synchronisation des **règles Cursor** (`.cursor/rules/`) afin qu’elles s’appliquent à tout l’IDE, sur tous les projets.

## Prérequis

- **PowerShell** (Windows)
- **Node.js** (pour la conversion des règles depuis cursor.directory)
- **Git** (pour cloner/mettre à jour [cursor.directory](https://cursor.directory))

## Scripts

### 1. Sync depuis cursor.directory (recommandé)

Récupère les règles depuis le dépôt [cursor.directory](https://github.com/ggdayup/cursor.directory), les convertit en `.mdc` et les installe dans ton dossier global utilisateur (`%USERPROFILE%\.cursor\rules\`). Elles s’appliquent alors à **tous** tes projets dans Cursor.

```powershell
# Depuis la racine du repo
.\scripts\sync-cursor-directory-rules.ps1
```

**Options :**

| Option        | Description |
|---------------|-------------|
| `-RepoRoot`   | Racine du repo (si tu n’es pas à la racine). |
| `-TargetDir`  | Dossier cible des règles (défaut : `$env:USERPROFILE\.cursor\rules`). |
| `-NoClone`    | Ne pas cloner/mettre à jour le repo ; utiliser uniquement le cache local. |
| `-WhatIf`     | Afficher les actions sans écrire. |

**Exemple avec cible personnalisée :**

```powershell
.\scripts\sync-cursor-directory-rules.ps1 -TargetDir "C:\Users\lapet\.cursor\rules"
```

Le cache du clone cursor.directory est dans `%LOCALAPPDATA%\cursor-rules-automation\cursor.directory`.

### 2. Installer les règles du projet courant

Si ce repo (ou un autre) contient déjà un dossier `.cursor/rules/` avec des `.mdc`, ce script les copie vers le dossier global utilisateur :

```powershell
.\scripts\install-cursor-rules.ps1
```

À lancer depuis la racine du **projet qui contient** `.cursor/rules/`.

## Résumé

| Script | Rôle |
|--------|------|
| `sync-cursor-directory-rules.ps1` | Clone cursor.directory → conversion TS → `.mdc` → copie vers règles globales. |
| `install-cursor-rules.ps1` | Copie les `.mdc` du projet courant vers les règles globales. |

Après exécution, redémarre Cursor si les nouvelles règles ne semblent pas prises en compte.
