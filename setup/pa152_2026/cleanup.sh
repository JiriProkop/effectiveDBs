#!/usr/bin/env bash
set -euo pipefail

echo "Stopping and removing container, network, and volume..."
docker compose down -v

echo "Done."
