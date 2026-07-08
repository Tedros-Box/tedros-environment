# Prepara os dados locais do Tedros.
#   -Database h2       (default) cria a pasta ~/.tedrosData e copia o init.sql do H2
#   -Database postgres sobe o PostgreSQL local via docker-compose-pg.yml
param(
    [ValidateSet("h2", "postgres")]
    [string]$Database = "h2"
)

if ($Database -eq "postgres") {
    $ScriptDir = $PSScriptRoot
    if ([string]::IsNullOrEmpty($ScriptDir)) {
        $ScriptDir = Get-Location
    }
    Write-Host "Starting local PostgreSQL (docker-compose-pg.yml)..."
    docker compose -f (Join-Path $ScriptDir "docker-compose-pg.yml") up -d
    Write-Host "PostgreSQL available at localhost:5432 (db=tedros, user=tdrs)."
    Write-Host "Schemas are created automatically by init-postgres.sql on first run."
    return
}

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
