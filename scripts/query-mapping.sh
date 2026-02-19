#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

DB_HOST="${MAPPING_DB_HOST:-mappingagent-sql}"
DB_PORT="${MAPPING_DB_PORT:-1433}"
DB_NAME="${MAPPING_DB:-MappingDW}"
DB_USER="${MSSQL_USER:-sa}"
DB_PASS="${MSSQL_SA_PASSWORD:-}"
CONTAINER_NAME="${MAPPING_SQL_CONTAINER:-mappingagent-sql}"
NETWORK_NAME="${MAPPING_DOCKER_NETWORK:-docker_default}"

if [[ -z "$DB_PASS" ]]; then
  echo "ERROR: MSSQL_SA_PASSWORD no está seteado (.env)." >&2
  exit 1
fi

QUERY="${1:-SELECT * FROM dbo.Mapping;}"

docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME" || {
  echo "ERROR: El contenedor '$CONTAINER_NAME' no está corriendo." >&2
  echo "Levantalo con: docker compose --env-file .env -f infra/docker/docker-compose.dev.yml up -d" >&2
  exit 1
}

docker run --rm --network "$NETWORK_NAME" \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd \
  -S "${CONTAINER_NAME},${DB_PORT}" \
  -U "$DB_USER" \
  -P "$DB_PASS" \
  -d "$DB_NAME" \
  -Q "$QUERY"
