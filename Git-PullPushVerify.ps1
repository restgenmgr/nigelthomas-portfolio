<#
.SYNOPSIS
    Verifies, pulls, and/or pushes a git repo with safety checks and ahead/behind reporting.

.DESCRIPTION
    Wraps common git workflow steps for a single repo:
      - Verify: fetches from origin and reports how many commits ahead/behind local is vs remote,
                plus any uncommitted local changes. Makes no changes.
      - Pull:   fetches and pulls latest from origin, then runs Verify.
      - Push:   requires -CommitMessage if there are uncommitted changes; stages, commits, and
                pushes them, then runs Verify.
      - All:    Verify -> Pull -> Verify -> commit+push (if -CommitMessage given) -> Verify.

.PARAMETER RepoPath
    Path to the local git repository. Defaults to the current directory.

.PARAMETER Action
    One of: Verify, Pull, Push, All.

.PARAMETER CommitMessage
    Required when Action is Push or All and there are uncommitted changes to push.

.EXAMPLE
    .\Git-PullPushVerify.ps1 -RepoPath "C:\projects\nigelthomas-portfolio" -Action Verify

.EXAMPLE
    .\Git-PullPushVerify.ps1 -RepoPath "C:\projects\nigelthomas-portfolio" -Action Pull

.EXAMPLE
    .\Git-PullPushVerify.ps1 -RepoPath "C:\projects\nigelthomas-portfolio" -Action Push -CommitMessage "Fix poster placement on blog pages"

.EXAMPLE
    .\Git-PullPushVerify.ps1 -RepoPath "C:\projects\nigelthomas-portfolio" -Action All -CommitMessage "Repair mojibake + move posters behind Infomatics button"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoPath = ".",

    [Parameter(Mandatory = $true)]
    [ValidateSet("Verify", "Pull", "Push", "All")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$CommitMessage
)

$ErrorActionPreference = "Stop"

function Assert-GitRepo {
    param([string]$Path)
    Push-Location $Path
    try {
        git rev-parse --is-inside-work-tree *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "'$Path' is not inside a git repository."
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-Verify {
    param([string]$Path)

    Push-Location $Path
    try {
        Write-Host ""
        Write-Host "=== Verify: $Path ===" -ForegroundColor Cyan

        Write-Host "Fetching from origin..." -ForegroundColor DarkGray
        git fetch origin *> $null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "git fetch failed. Check your network/remote configuration."
            return
        }

        $branch = (git rev-parse --abbrev-ref HEAD).Trim()
        Write-Host "Current branch: $branch"

        $counts = git rev-list --left-right --count "origin/$branch...HEAD" 2>$null
        if ($LASTEXITCODE -eq 0 -and $counts) {
            $parts = $counts -split "\s+"
            $behind = $parts[0]
            $ahead  = $parts[1]
            Write-Host "Ahead of origin/$branch by:  $ahead commit(s)"
            Write-Host "Behind origin/$branch by:    $behind commit(s)"
        }
        else {
            Write-Warning "Could not compare against origin/$branch (branch may not exist on remote yet)."
        }

        $status = git status --porcelain
        if ($status) {
            Write-Host ""
            Write-Host "Uncommitted local changes:" -ForegroundColor Yellow
            git status --short
        }
        else {
            Write-Host ""
            Write-Host "Working tree clean -- no uncommitted changes." -ForegroundColor Green
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-Pull {
    param([string]$Path)

    Push-Location $Path
    try {
        Write-Host ""
        Write-Host "=== Pull: $Path ===" -ForegroundColor Cyan

        $status = git status --porcelain
        if ($status) {
            Write-Warning "You have uncommitted local changes. Pulling anyway may cause conflicts."
            Write-Host "Uncommitted changes:" -ForegroundColor Yellow
            git status --short
        }

        git pull
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "git pull failed. Resolve any conflicts before continuing."
            return $false
        }
        return $true
    }
    finally {
        Pop-Location
    }
}

function Invoke-Push {
    param(
        [string]$Path,
        [string]$Message
    )

    Push-Location $Path
    try {
        Write-Host ""
        Write-Host "=== Push: $Path ===" -ForegroundColor Cyan

        $status = git status --porcelain
        if (-not $status) {
            Write-Host "No local changes to commit. Nothing to push." -ForegroundColor Green
            return
        }

        if (-not $Message -or $Message.Trim() -eq "") {
            throw "Uncommitted changes exist but no -CommitMessage was provided. Aborting push. Re-run with -CommitMessage `"your message here`"."
        }

        Write-Host "Staging all changes..." -ForegroundColor DarkGray
        git add -A

        Write-Host "Committing with message: `"$Message`"" -ForegroundColor DarkGray
        git commit -m "$Message"
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "git commit failed."
            return
        }

        Write-Host "Pushing to origin..." -ForegroundColor DarkGray
        git push
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "git push failed. Check your remote/auth configuration."
            return
        }

        Write-Host "Push complete." -ForegroundColor Green
    }
    finally {
        Pop-Location
    }
}

# --- Main ---

Assert-GitRepo -Path $RepoPath

switch ($Action) {
    "Verify" {
        Invoke-Verify -Path $RepoPath
    }
    "Pull" {
        Invoke-Pull -Path $RepoPath | Out-Null
        Invoke-Verify -Path $RepoPath
    }
    "Push" {
        Invoke-Push -Path $RepoPath -Message $CommitMessage
        Invoke-Verify -Path $RepoPath
    }
    "All" {
        Invoke-Verify -Path $RepoPath
        $pulled = Invoke-Pull -Path $RepoPath
        Invoke-Verify -Path $RepoPath
        if ($pulled) {
            Invoke-Push -Path $RepoPath -Message $CommitMessage
            Invoke-Verify -Path $RepoPath
        }
        else {
            Write-Warning "Skipping push because pull did not complete cleanly."
        }
    }
}
