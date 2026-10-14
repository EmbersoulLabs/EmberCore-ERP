# Build Flutter web (production Firebase) and deploy to embercore-erp hosting.
# Copy paths are anchored at the repository root. Do not resolve build\web after
# changing directory into firebase\. hosting:releases:list is not a command in
# firebase-tools 14.27.0, and --limit is not accepted. Use hosting:channel:list.
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host "Building production web (embercore-erp)..."
flutter build web --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$webBuild = Join-Path $repoRoot "build\web"
if (-not (Test-Path (Join-Path $webBuild "index.html"))) {
    throw "Missing $webBuild\index.html. The web build must come from the repository root."
}

$publicDir = Join-Path $repoRoot "firebase\public"
if (-not (Test-Path $publicDir)) {
    New-Item -ItemType Directory -Path $publicDir | Out-Null
}
Write-Host "Copying $webBuild -> $publicDir ..."
Copy-Item -Recurse -Force (Join-Path $webBuild "*") $publicDir

Set-Location (Join-Path $repoRoot "firebase")
Write-Host "Deploying hosting + firestore rules + storage to production..."
npm run deploy:production

Write-Host ""
Write-Host "Done. Open https://embercore-erp.web.app and hard-refresh (Ctrl+Shift+R)."
Write-Host "Release list: npx firebase hosting:channel:list --project embercore-erp"
