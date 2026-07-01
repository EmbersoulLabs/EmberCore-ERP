# Build Flutter web (embercore-erp-staging) and deploy Hosting + bootstrap.
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
Set-Location $repoRoot

Write-Host "Building Flutter web (APP_ENV=staging -> embercore-erp-staging)..." -ForegroundColor Cyan
flutter build web --release --dart-define=APP_ENV=staging
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$publicDir = Join-Path $repoRoot "firebase\public"
if (Test-Path $publicDir) {
    Remove-Item -Recurse -Force $publicDir
}
New-Item -ItemType Directory -Force -Path $publicDir | Out-Null
Copy-Item -Recurse -Force (Join-Path $repoRoot "build\web\*") $publicDir

Set-Location (Join-Path $repoRoot "firebase")
firebase use staging

Write-Host "Deploying Firestore indexes (rules may need retry on 503)..." -ForegroundColor Cyan
firebase deploy --only firestore:indexes --project embercore-erp-staging
if ($LASTEXITCODE -ne 0) { Write-Host "Indexes deploy failed." -ForegroundColor Yellow }

firebase deploy --only firestore:rules --project embercore-erp-staging
if ($LASTEXITCODE -ne 0) {
    Write-Host "Rules deploy failed (often transient 503) - retry manually." -ForegroundColor Yellow
}

if ($env:STAGING_ADMIN_PASSWORD) {
    Write-Host "Bootstrapping staging admin + staging_company..." -ForegroundColor Cyan
    npm run bootstrap:staging
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Bootstrap failed - need embercore-erp-staging service account key. See docs/STAGING_EMBERCORE.md" -ForegroundColor Yellow
    }
} else {
    Write-Host "STAGING_ADMIN_PASSWORD not set - skipping bootstrap." -ForegroundColor Yellow
}

Write-Host "Deploying Hosting..." -ForegroundColor Cyan
firebase deploy --only "hosting" --project embercore-erp-staging
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Staging URL: https://embercore-erp-staging.web.app" -ForegroundColor Green
Write-Host "Login: staging.admin@embersoullabs.com" -ForegroundColor Green
Write-Host "UI checklist: docs/PHASE_A_UI_SMOKE_CHECKLIST.md" -ForegroundColor Green

if ($env:STAGING_ADMIN_PASSWORD) {
    npm run smoke:staging
}
