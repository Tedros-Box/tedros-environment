$DataFolder = Join-Path $HOME ".tedrosData"
Write-Host "Checking data folder: $DataFolder"

if (-not (Test-Path $DataFolder)) {
    New-Item -ItemType Directory -Force -Path $DataFolder | Out-Null
    $h2Folder = Join-Path $DataFolder "h2"
    if (-not (Test-Path $h2Folder)) {
        New-Item -ItemType Directory -Force -Path $h2Folder | Out-Null
    }
    Write-Host "Data folder created!"
} else {
    Write-Host "Data folder already exist!"
}

$sql = "init.sql"
Write-Host "Checking data file: $sql"
$targetSqlFile = Join-Path $DataFolder $sql

if (-not (Test-Path $targetSqlFile)) {
    # Resolve source sql relative to this script's directory
    $ScriptDir = $PSScriptRoot
    if ([string]::IsNullOrEmpty($ScriptDir)) {
        $ScriptDir = Get-Location
    }
    
    $sourceSqlFile = Join-Path $ScriptDir $sql

    if (Test-Path $sourceSqlFile) {
        Copy-Item -Path $sourceSqlFile -Destination $targetSqlFile
        Write-Host "Data file created!"
    } else {
        Write-Host "Error: source file $sql not found at $sourceSqlFile" -ForegroundColor Red
    }
} else {
    Write-Host "Data file already exist!"
}
