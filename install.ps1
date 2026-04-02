# install.ps1 — Install WormScript AI Skills (Windows)
# Usage: .\install.ps1 [-Tool <tool>] [-Skill <skill>] [-ProjectDir <path>]
#
# Tools:  claude-code (default), cursor, copilot, windsurf, all
# Skills: wrm-data-builder, wrm, all (default: all)

param(
  [string]$Tool       = "claude-code",
  [string]$Skill      = "all",
  [string]$ProjectDir = (Get-Location).Path
)

$RepoDir   = $PSScriptRoot
$SkillsDir = "$env:USERPROFILE\.claude\skills"
$AllSkills = @("wrm", "wrm-data-builder")

Write-Host "WormScript AI Skills Installer" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "Tool:        $Tool"
Write-Host "Skill:       $Skill"
Write-Host "Repo:        $RepoDir"

function Get-Skills {
  if ($Skill -eq "all") { return $AllSkills }
  return @($Skill)
}

# ── Helpers ────────────────────────────────────────────────────────────────────

function Install-ClaudeSkill($skillName) {
  $src = "$RepoDir\$skillName"
  if (-not (Test-Path $src)) { Write-Host "  [skip] Skill '$skillName' not found"; return }
  New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
  Copy-Item -Recurse -Force $src "$SkillsDir\"
  Write-Host "  Copied $skillName -> $SkillsDir\$skillName"
}

function Install-CursorSkill($skillName) {
  $adapter = "$RepoDir\$skillName\adapters\cursor.mdc"
  if (-not (Test-Path $adapter)) { Write-Host "  [skip] No cursor adapter for '$skillName'"; return }
  $dest = "$ProjectDir\.cursor\rules"
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Copy-Item -Force $adapter "$dest\$skillName.mdc"
  Write-Host "  Copied cursor.mdc -> $dest\$skillName.mdc"
}

function Install-CopilotSkill($skillName) {
  $adapter = "$RepoDir\$skillName\adapters\copilot-instructions.md"
  if (-not (Test-Path $adapter)) { Write-Host "  [skip] No copilot adapter for '$skillName'"; return }
  $dest = "$ProjectDir\.github"
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  $destFile = "$dest\copilot-instructions.md"
  if (Test-Path $destFile) {
    Add-Content $destFile "`n---`n"
    Get-Content $adapter | Add-Content $destFile
    Write-Host "  Appended $skillName -> $destFile"
  } else {
    Copy-Item -Force $adapter $destFile
    Write-Host "  Copied copilot-instructions.md -> $destFile"
  }
}

function Install-WindsurfSkill($skillName) {
  $adapter = "$RepoDir\$skillName\adapters\windsurf.rules"
  if (-not (Test-Path $adapter)) { Write-Host "  [skip] No windsurf adapter for '$skillName'"; return }
  $destFile = "$ProjectDir\.windsurfrules"
  if (Test-Path $destFile) {
    Add-Content $destFile "`n---`n"
    Get-Content $adapter | Add-Content $destFile
    Write-Host "  Appended $skillName -> $destFile"
  } else {
    Copy-Item -Force $adapter $destFile
    Write-Host "  Copied windsurf.rules -> $destFile"
  }
}

# ── Tool installers ─────────────────────────────────────────────────────────────

function Install-ClaudeCode {
  Write-Host ""
  Write-Host "Installing for Claude Code..." -ForegroundColor Green
  foreach ($s in Get-Skills) { Install-ClaudeSkill $s }
  Write-Host ""
  Write-Host "Done. Restart Claude Code to load the skills." -ForegroundColor Green
}

function Install-Cursor {
  Write-Host ""
  Write-Host "Installing for Cursor (project: $ProjectDir)..." -ForegroundColor Green
  foreach ($s in Get-Skills) { Install-CursorSkill $s }
  Write-Host ""
  Write-Host "Done. Rules activate automatically in Cursor." -ForegroundColor Green
}

function Install-Copilot {
  Write-Host ""
  Write-Host "Installing for GitHub Copilot (project: $ProjectDir)..." -ForegroundColor Green
  foreach ($s in Get-Skills) { Install-CopilotSkill $s }
  Write-Host ""
  Write-Host "Done. Copilot loads instructions automatically for this project." -ForegroundColor Green
}

function Install-Windsurf {
  Write-Host ""
  Write-Host "Installing for Windsurf (project: $ProjectDir)..." -ForegroundColor Green
  foreach ($s in Get-Skills) { Install-WindsurfSkill $s }
  Write-Host ""
  Write-Host "Done. Windsurf loads rules automatically." -ForegroundColor Green
}

# ── Dispatch ───────────────────────────────────────────────────────────────────

switch ($Tool) {
  "claude-code" { Install-ClaudeCode }
  "cursor"      { Install-Cursor }
  "copilot"     { Install-Copilot }
  "windsurf"    { Install-Windsurf }
  "all"         { Install-ClaudeCode; Install-Cursor; Install-Copilot; Install-Windsurf }
  default {
    Write-Host "Unknown tool: $Tool" -ForegroundColor Red
    Write-Host "Valid options: claude-code, cursor, copilot, windsurf, all"
    exit 1
  }
}
