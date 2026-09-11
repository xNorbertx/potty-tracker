param(
    [ValidateSet('auto', 'edge', 'chrome', 'web-server')]
    [string]$Device = 'auto',
    [ValidateRange(1024, 65535)]
    [int]$Port = 8080,
    [string]$FlutterSdk
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot

if ($FlutterSdk) {
    $flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
} elseif ($env:FLUTTER_ROOT) {
    $flutter = Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat'
} elseif (Test-Path (Join-Path (Split-Path $projectRoot -Parent) 'flutter-sdk\bin\flutter.bat')) {
    $flutter = Join-Path (Split-Path $projectRoot -Parent) 'flutter-sdk\bin\flutter.bat'
} else {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if (!$command) {
        throw 'Flutter was not found. Install Flutter 3.27.4, set FLUTTER_ROOT, or pass -FlutterSdk <SDK folder>.'
    }
    $flutter = $command.Source
}

if (!(Test-Path -LiteralPath $flutter)) {
    throw "Flutter executable was not found at $flutter"
}
if (!(Test-Path (Join-Path $projectRoot 'lib\firebase_options.dart'))) {
    throw 'Missing lib\firebase_options.dart. Copy the example and configure your Firebase project as described in README.md.'
}

$listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
if ($listener) {
    throw "Port $Port is already in use. If the preview is already running, open http://localhost:$Port. Otherwise choose another port with -Port 8081."
}

Push-Location $projectRoot
try {
    Write-Host 'Preparing Potty Tracker...' -ForegroundColor Green
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency setup failed.' }

    if ($Device -eq 'auto') {
        $deviceJson = & $flutter devices --machine
        if ($LASTEXITCODE -ne 0) { throw 'Flutter device detection failed.' }
        $availableDevices = @($deviceJson | ConvertFrom-Json)
        $Device = 'web-server'
        foreach ($candidate in @('edge', 'chrome')) {
            if ($availableDevices.id -contains $candidate) {
                $Device = $candidate
                break
            }
        }
        Write-Host "Selected preview device: $Device"
    }

    Write-Host "Local preview: http://localhost:$Port" -ForegroundColor Green
    Write-Host 'This uses the configured Firebase backend; saved changes affect the shared diary.'
    Write-Host 'Keep this terminal open. Press R to restart after code changes, or q to stop.'
    if ($Device -eq 'web-server') {
        Write-Host 'Open the URL in your browser once Flutter reports that the server is ready.'
    }
    & $flutter run -d $Device --web-hostname localhost --web-port $Port
    if ($LASTEXITCODE -ne 0) { throw 'Flutter preview exited with an error. See the output above.' }
} finally {
    Pop-Location
}
