<#
.SYNOPSIS
    Syncs the local and remote fork branches with the original upstream repository.
.DESCRIPTION
    1. Fetches latest commits from upstream (storytold/filmcraft).
    2. Updates the local 'main' branch cleanly to match upstream/main.
    3. Pushes 'main' to origin (your GitHub fork), if configured.
    4. Merges/rebases updates into your current feature branch without conflicts.
#>

param (
    [string]$TargetBranch = ""
)

$ErrorActionPreference = "Stop"

Write-Host "==> Fetching latest changes from upstream..." -ForegroundColor Cyan
git fetch upstream

$currentBranch = (git branch --show-current).Trim()
Write-Host "Current branch: $currentBranch" -ForegroundColor Yellow

# Ensure working directory is clean
$status = git status --porcelain
if ($status) {
    Write-Warning "You have uncommitted changes. Stashing them temporarily..."
    git stash
    $stashed = $true
} else {
    $stashed = $false
}

try {
    # 1. Update main branch
    Write-Host "==> Updating main branch from upstream/main..." -ForegroundColor Cyan
    git checkout main
    git merge --ff-only upstream/main

    # Push to origin if origin remote exists
    $origin = git remote | Where-Object { $_ -eq "origin" }
    if ($origin) {
        Write-Host "==> Pushing updated main to origin (your fork)..." -ForegroundColor Cyan
        git push origin main
    } else {
        Write-Host "Note: 'origin' remote is not configured yet. Run 'git remote add origin <your-fork-url>'" -ForegroundColor DarkYellow
    }

    # 2. Return to working branch if different from main
    if ($currentBranch -ne "main" -and $currentBranch -ne "") {
        Write-Host "==> Switching back to $currentBranch..." -ForegroundColor Cyan
        git checkout $currentBranch

        Write-Host "==> Merging main into $currentBranch..." -ForegroundColor Cyan
        git merge main
        Write-Host "==> Successfully synced $currentBranch with upstream/main!" -ForegroundColor Green
    }
}
finally {
    if ($stashed) {
        Write-Host "==> Restoring stashed changes..." -ForegroundColor Yellow
        git stash pop
    }
}

Write-Host "==> All synced successfully!" -ForegroundColor Green
