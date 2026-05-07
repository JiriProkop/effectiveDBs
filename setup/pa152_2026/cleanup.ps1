$ErrorActionPreference = "Stop"

Write-Host "Stopping and removing container, network, and volume..."
docker compose down -v

Write-Host "Done."
