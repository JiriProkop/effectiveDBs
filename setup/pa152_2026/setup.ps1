\
param(
  [Parameter(Mandatory = $true)]
  [string]$SqlFile
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SqlFile)) {
  Write-Host "File not found: $SqlFile"
  Write-Host "You need to download your dataset first. https://disa.fi.muni.cz/projects/PA152/hw/"
  exit 1
}

Write-Host "Starting PostgreSQL container..."
docker compose up -d | Out-Null

Write-Host "Waiting 20 seconds for PostgreSQL startup..."
Start-Sleep -Seconds 20

$baseName = Split-Path $SqlFile -Leaf

Write-Host "Importing dataset $baseName into pa152_db..."
Write-Host "This may take a few minutes (about 1 million records)."
docker exec -i pa152 psql -U postgres -d pa152_db -f "/workspace/$baseName" *> $null

Write-Host "Running VACUUM ANALYZE..."
docker exec -i pa152 psql -U postgres -d pa152_db -c "VACUUM ANALYZE;" *> $null

Write-Host ""
Write-Host "Creating EXPLAIN helper scripts..."

$explainScript = @'
for f in /workspace/query_*.sql; do
  [ -f "$f" ] || continue
  case "$f" in
    *_explain.sql) continue ;;
  esac
  base=$(basename "$f" .sql)
  {
    echo "EXPLAIN (ANALYZE, BUFFERS)"
    cat "$f"
  } > "/workspace/${base}_explain.sql"
done
'@

docker exec -i pa152 sh -c $explainScript

Write-Host ""
Write-Host "Done."
Write-Host "Connection for host tools:"
Write-Host "  host=localhost port=5432 dbname=pa152_db user=user password=pa152pwd"
Write-Host ""
Write-Host "Example psql connection:"
Write-Host "  docker exec -e PGPASSWORD=pa152pwd -it pa152 psql -h localhost -p 5432 -U user -d pa152_db"
Write-Host ""
Write-Host "Run query_A.sql from inside psql:"
Write-Host "  pa152_db=# \i /workspace/query_A.sql"
Write-Host ""
Write-Host "Run EXPLAIN script from inside psql:"
Write-Host "  pa152_db=# \i /workspace/query_A_explain.sql"
Write-Host ""
Write-Host "Example benchmark:"
Write-Host "  docker exec -e PGPASSWORD=pa152pwd -it pa152 pgbench -n -f /workspace/query_Q1.sql -t 50 -c 1 -j 1 -U user pa152_db"
