$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/affaan-m/everything-claude-code.git"
$tempDir = Join-Path $env:TEMP "ecc-skills-sync"
$targetDir = Join-Path $PSScriptRoot "..\.github\skills"

if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}

git clone --filter=blob:none --no-checkout $repoUrl $tempDir | Out-Null
Push-Location $tempDir

git sparse-checkout init --cone | Out-Null
git sparse-checkout set skills | Out-Null
git checkout main | Out-Null

Pop-Location

$src = Join-Path $tempDir "skills"

if (Test-Path $targetDir) {
    Remove-Item -Recurse -Force $targetDir
}

New-Item -ItemType Directory -Force -Path (Split-Path $targetDir -Parent) | Out-Null
Copy-Item -Path $src -Destination $targetDir -Recurse

$count = (Get-ChildItem $targetDir -Directory).Count
Write-Output "Sync complete. Skills count: $count"
Write-Output "Target: $targetDir"
