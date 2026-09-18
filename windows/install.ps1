# Bootstrap a Windows machine from this repo.
# Run from an elevated PowerShell (symlinks need admin, or Developer Mode on):
#   powershell -ExecutionPolicy Bypass -File .\windows\install.ps1

$ErrorActionPreference = 'Stop'

$RepoDir = Split-Path -Parent $PSScriptRoot
$Stamp   = Get-Date -Format 'yyyyMMddHHmmss'

function Link-Config {
    param([string]$Source, [string]$Dest)

    $src = Join-Path $RepoDir $Source
    if (-not (Test-Path $src)) { Write-Host "skip   $Source (not in repo)"; return }

    $parent = Split-Path -Parent $Dest
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }

    if (Test-Path $Dest) {
        Move-Item $Dest "$Dest.backup-$Stamp"
        Write-Host "backup $Dest"
    }

    New-Item -ItemType SymbolicLink -Path $Dest -Target $src | Out-Null
    Write-Host "link   $Dest -> $src"
}

# Shared config. Windows vim reads _vimrc and vimfiles\, but also honours
# ~/.vimrc and ~/.vim when they exist, so link both names for the rc file.
Link-Config 'shared\vim\vimrc'                          "$HOME\_vimrc"
Link-Config 'shared\vim\ftplugin\c.vim'                 "$HOME\vimfiles\ftplugin\c.vim"
Link-Config 'shared\vim\ftplugin\gitcommit.vim'         "$HOME\vimfiles\ftplugin\gitcommit.vim"
Link-Config 'shared\vim\templates\template.c'           "$HOME\.vim\templates\template.c"
Link-Config 'shared\vim\templates\solution_template.py' "$HOME\.vim\templates\solution_template.py"
Link-Config 'shared\git\gitconfig'                      "$HOME\.gitconfig"
Link-Config 'shared\git\gitignore_global'               "$HOME\.gitignore_global"

# Windows-specific
Link-Config 'windows\cmd\alias.cmd' "$HOME\alias.cmd"

# Machine-local files (never tracked)
if (-not (Test-Path "$HOME\.gitconfig.local")) {
    @"
[user]
	name = Your Name
	email = you@example.com
"@ | Set-Content "$HOME\.gitconfig.local"
    Write-Host "created $HOME\.gitconfig.local (fill in your identity)"
}

Write-Host ''
Write-Host 'Done. To auto-run the cmd.exe aliases, point the console AutoRun at it:'
Write-Host '  reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /d "%USERPROFILE%\alias.cmd" /f'
