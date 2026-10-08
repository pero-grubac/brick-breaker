# Builds every release (Windows, Web, Android) and packs the files for a GitHub release.
#
#   powershell -File tools/build_release.ps1 -Version 1.0.0
#
# Output in build/release/:
#   BrickBreaker-<version>-windows.zip   the .exe
#   BrickBreaker-<version>-web.zip       the web build (upload to itch.io or any static host)
#   BrickBreaker-<version>.apk           signed Android APK
#
# The Android signing key lives outside the project, in %USERPROFILE%\.brickbreaker-keys
# (README-keystore.txt has the password). It is handed to Godot through environment variables,
# so no password ever ends up in the repo.

param(
    [string]$Version = "1.0.0",
    [string]$Godot = "E:\Programs\Godot\Godot_v4.7.2-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$keys = Join-Path $env:USERPROFILE ".brickbreaker-keys"
$keyInfo = Join-Path $keys "README-keystore.txt"
if (-not (Test-Path $keyInfo)) { throw "Android keystore not found in $keys" }
$password = (Select-String -Path $keyInfo -Pattern "^password: (.+)$").Matches[0].Groups[1].Value
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = Join-Path $keys "brickbreaker-release.jks"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "brickbreaker"
$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $password

$builds = @(
    @{ Preset = "Windows Desktop"; Path = "build/windows/BrickBreaker.exe" },
    @{ Preset = "Web"; Path = "build/web/index.html" },
    @{ Preset = "Android"; Path = "build/android/BrickBreaker.apk" }
)
foreach ($build in $builds) {
    New-Item -ItemType Directory -Force (Split-Path $build.Path) | Out-Null
    Write-Host "Exporting $($build.Preset)..."
    & $Godot --headless --path . --export-release $build.Preset $build.Path
    if ($LASTEXITCODE -ne 0) { throw "Export of $($build.Preset) failed" }
}

$release = "build/release"
New-Item -ItemType Directory -Force $release | Out-Null
Compress-Archive -Force -Path "build/windows/BrickBreaker.exe" -DestinationPath "$release/BrickBreaker-$Version-windows.zip"
Compress-Archive -Force -Path "build/web/*" -DestinationPath "$release/BrickBreaker-$Version-web.zip"
Copy-Item -Force "build/android/BrickBreaker.apk" "$release/BrickBreaker-$Version.apk"
Get-ChildItem $release | Format-Table Name, Length
