# SQL Course - One-Time Setup (PowerShell)
# Run from repo root: .\setup.ps1

Write-Host "Checking Docker..." -ForegroundColor Yellow
$null = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker is not running. Start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

Write-Host "Stopping containers..." -ForegroundColor Yellow
docker-compose down 2>$null

Write-Host "Removing old database volume..." -ForegroundColor Yellow
docker volume rm sql_course-1_pgdata 2>$null

Write-Host "Starting PostgreSQL..." -ForegroundColor Yellow
docker-compose up -d

Write-Host "Waiting 15 seconds for PostgreSQL to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "Loading schema..." -ForegroundColor Yellow
Get-Content module-01-sql-concepts/project/schema.sql | docker exec -i sqlcourse-postgres psql -U postgres -d postgres
Get-Content module-01-sql-concepts/project/constraints.sql | docker exec -i sqlcourse-postgres psql -U postgres -d postgres
Get-Content module-01-sql-concepts/project/seed_data.sql | docker exec -i sqlcourse-postgres psql -U postgres -d postgres

Write-Host "`nDone! Connect with:" -ForegroundColor Green
Write-Host "  psql:    docker exec -it sqlcourse-postgres psql -U postgres -d postgres" -ForegroundColor Cyan
Write-Host "  pgAdmin: localhost:5432 | db=postgres | user=postgres | password=postgres" -ForegroundColor Cyan
Write-Host "  DBeaver: localhost:5432 | db=postgres | user=postgres | password=postgres" -ForegroundColor Cyan
Write-Host "`nThen run: SELECT * FROM customers LIMIT 5;" -ForegroundColor Gray
