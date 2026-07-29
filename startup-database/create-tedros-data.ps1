# Prepara os dados locais do Tedros.
#   -Database postgres  (default) sobe o PostgreSQL local via docker-compose-pg.yml
#   futuro: -Database oracle  (estender ValidateSet + compose dedicado)
param(
    # futuro: adicionar "oracle" ao ValidateSet
    [ValidateSet("postgres")]
    [string]$Database = "postgres"
)

$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Get-Location
}

if ($Database -eq "postgres") {
    Write-Host "Starting local PostgreSQL (docker-compose-pg.yml)..."
    docker compose -f (Join-Path $ScriptDir "docker-compose-pg.yml") up -d
    Write-Host "PostgreSQL available at localhost:5432 (db=tedros, user=tdrs)."
    Write-Host "Schemas are created automatically by init-postgres.sql on first run."
    return
}

Write-Host "Unsupported database vendor: $Database" -ForegroundColor Red
exit 1
