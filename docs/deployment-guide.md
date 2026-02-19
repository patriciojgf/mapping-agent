# Deployment Guide (Local + Public Demo)

Guía paso a paso para levantar la POC completa y dejarla accesible desde internet con Cloudflare Quick Tunnel.

## 1) Requisitos

- macOS
- Docker Desktop
- .NET SDK 8
- `cloudflared` (opcional para exponer públicamente)
- `curl`

## 2) Clonar y preparar entorno

```bash
git clone <tu-repo-publico>
cd mapping-agent
cp .env.example .env
```

Editar `.env`:

- `MSSQL_SA_PASSWORD`: contraseña fuerte para SQL
- `MAPPING_DB`: `MappingDW`
- `MAPPING_DB_HOST`: `localhost`
- `MAPPING_DB_PORT`: `1433`
- `API_KEY`: clave para proteger endpoints (`X-API-Key`)

## 3) Levantar SQL Server

```bash
docker compose --env-file .env -f infra/docker/docker-compose.dev.yml up -d
docker ps --filter name=mappingagent-sql
```

Esperado: contenedor `mappingagent-sql` en estado `Up`.

## 4) Crear base y esquema

```bash
set -a; source .env; set +a

docker run --rm --network docker_default -v "$PWD/infra/docker/sql:/scripts:ro" \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd \
  -S mappingagent-sql -U sa -P "$MSSQL_SA_PASSWORD" \
  -d master -i /scripts/001_create_schema.sql -b
```

## 5) Carga mínima (opcional)

```bash
docker run --rm --network docker_default -v "$PWD/infra/docker/sql:/scripts:ro" \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd \
  -S mappingagent-sql -U sa -P "$MSSQL_SA_PASSWORD" \
  -d MappingDW -i /scripts/002_seed_demo.sql -b
```

## 6) Carga de CSV reales

Antes de cargar, colocar CSV en `data/` con nombres exactos definidos en `data/README.md`.

Copiar al contenedor:

```bash
docker exec mappingagent-sql mkdir -p /var/opt/mssql/import
docker cp data/. mappingagent-sql:/var/opt/mssql/import/
```

Ejecutar import masivo:

```bash
docker run --rm --network docker_default -v "$PWD/infra/docker/sql:/scripts:ro" \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd \
  -S mappingagent-sql -U sa -P "$MSSQL_SA_PASSWORD" \
  -d master -i /scripts/003_import_data_csv.sql -b
```

Validar datos:

```bash
docker run --rm --network docker_default mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd \
  -S mappingagent-sql -U sa -P "$MSSQL_SA_PASSWORD" \
  -d MappingDW \
  -Q "SELECT TOP (5) Id, Nombre FROM dbo.Mapping ORDER BY Id"
```

## 7) Levantar API

```bash
set -a; source .env; set +a
dotnet run --project src/MappingAgent.Api --urls http://127.0.0.1:5050
```

Checks:

```bash
curl http://127.0.0.1:5050/health
curl -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
  -d '{"sql":"SELECT TOP (1) 1 AS One"}' \
  http://127.0.0.1:5050/api/sql/validate
```

## 8) Exponer API a internet (sin dominio)

Instalar:

```bash
brew install cloudflared
```

Ejecutar tunnel:

```bash
scripts/run-tunnel.sh 5050
```

Tomar URL `https://<random>.trycloudflare.com`.

Validar:

```bash
curl https://<random>.trycloudflare.com/health
curl -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
  -d '{"sql":"SELECT TOP (1) 1 AS One"}' \
  https://<random>.trycloudflare.com/api/sql/validate
```

## 9) Test suite

```bash
scripts/run-tests.sh
```

## 10) Lo que NO se expone

- SQL Server no se publica directamente.
- Solo se expone la API HTTP protegida por API key.
- Nunca subir `.env` ni CSV reales.
