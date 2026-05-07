\
#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: ./setup.sh <UCO>.sql"
  exit 1
fi

SQL_FILE="$1"

if [ ! -f "$SQL_FILE" ]; then
  echo "File not found: $SQL_FILE"
  echo "You need to download your dataset first. https://disa.fi.muni.cz/projects/PA152/hw/"
  exit 1
fi

echo "Starting PostgreSQL container..."
docker compose up -d

echo "Waiting 20 seconds for PostgreSQL startup..."
sleep 20

echo "Importing dataset $SQL_FILE into pa152_db..."
echo "This may take a few minutes (about 1 million records)."
BASENAME="$(basename "$SQL_FILE")"

docker exec -i pa152 \
  psql -U postgres -d pa152_db -f "/workspace/$BASENAME" \
  > /dev/null 2>&1

echo "Running VACUUM ANALYZE..."
docker exec -i pa152 \
  psql -U postgres -d pa152_db -c "VACUUM ANALYZE;" \
  > /dev/null 2>&1

echo
echo "Creating EXPLAIN helper scripts..."

docker exec -i pa152 sh -c '
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
'

echo
echo "Done."
echo "Connection for host tools:"
echo "  host=localhost port=5432 dbname=pa152_db user=user password=pa152pwd"
echo
echo "Example psql connection:"
echo "  docker exec -e PGPASSWORD=pa152pwd -it pa152 psql -h localhost -p 5432 -U user -d pa152_db"
echo
echo "Run query_A.sql from inside psql:"
echo "  pa152_db=# \\i /workspace/query_A.sql"
echo
echo "Run EXPLAIN script from inside psql:"
echo "  pa152_db=# \\i /workspace/query_A_explain.sql"
echo
echo "Example benchmark:"
echo "  docker exec -e PGPASSWORD=pa152pwd -it pa152 pgbench -n -f /workspace/query_Q1.sql -t 50 -c 1 -j 1 -U user pa152_db"
