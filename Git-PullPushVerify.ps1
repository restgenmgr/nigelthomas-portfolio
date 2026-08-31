# Just check repo health / sync status — changes nothing
.\Git-PullPushVerify.ps1 -RepoPath "C:\projects\nigelthomas-portfolio" -Action Verify

# Pull latest from GitHub, then verify
.\Git-PullPushVerify.ps1 -RepoPath "C:\projects\nigelthomas-portfolio" -Action Pull

# Commit whatever's changed and push it
.\Git-PullPushVerify.ps1 -RepoPath "C:\projects\nigelthomas-portfolio" -Action Push -CommitMessage "Fix poster placement on blog pages"

# Full cycle: verify -> pull -> verify -> commit+push -> verify
.\Git-PullPushVerify.ps1 -RepoPath "C:\projects\nigelthomas-portfolio" -Action All -CommitMessage "Repair mojibake + move posters behind Infomatics button"
