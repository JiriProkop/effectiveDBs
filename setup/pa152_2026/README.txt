\
PA152 2026 Complete Setup Bundle

Contents:
- docker-compose.yml
- setup.sh / setup.ps1
- cleanup.sh / cleanup.ps1
- query_*.sql files

Usage:
1) Put your <UCO>.sql dataset into this directory.
2) Run setup:

Linux/macOS:
  ./setup.sh <UCO>.sql

Windows PowerShell:
  .\setup.ps1 <UCO>.sql

Then connect:
  docker exec -e PGPASSWORD=pa152pwd -it pa152 psql -h localhost -p 5432 -U user -d pa152_db

Inside psql:
  \i /workspace/query_A.sql
  \i /workspace/query_A_explain.sql
