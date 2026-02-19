# Mapping Agent POC (.NET 8 + SQL Server + Copilot Studio)

POC para responder preguntas de negocio sobre metadata de mappings con esta arquitectura:

- SQL Server local (`MappingDW`) en Docker
- API ASP.NET Core Minimal API
- Exposición pública temporal con Cloudflare Quick Tunnel
- Consumo desde Copilot Studio (Custom Connector OpenAPI)

Este repo está preparado para publicarse en GitHub público sin incluir datos sensibles.

---

## Índice

- [Qué hace la API](#qué-hace-la-api)
- [Arquitectura](#arquitectura)
- [Quickstart](#quickstart)
- [Documentación detallada](#documentación-detallada)
- [Estructura del proyecto (archivo por archivo)](#estructura-del-proyecto-archivo-por-archivo)
- [Seguridad y alcance](#seguridad-y-alcance)
- [Tests](#tests)
- [Licencia](#licencia)

Guías en `docs/`:

- [Deployment guide](docs/01-deployment-guide.md)
- [Cloudflare quick tunnel](docs/02-cloudflare-tunnel.md)
- [Copilot Studio + Power Automate](docs/03-copilot-power-automate-guide.md)
- [Checklist para repo público](docs/04-public-repo-checklist.md)
- [OpenAPI para Copilot](docs/05-mappingdw-openapi.json)
- [Formato de data CSV](data/README.md)

---

## Qué hace la API

Endpoints:

- `GET /health`
- `POST /api/sql/validate`
- `POST /api/sql/query`

Características:

- SQL libre de solo lectura con barandas
- API key por header `X-API-Key`
- Respuesta tabular compatible con Copilot (`rows` como array de objetos)

Ejemplo de response de `/api/sql/query`:

```json
{
  "sql": "SELECT TOP (3) Id, Nombre FROM dbo.Mapping ORDER BY Id",
  "columns": ["Id", "Nombre"],
  "rows": [
    { "Id": 1, "Nombre": "000_Fuera_de_etapa" },
    { "Id": 2, "Nombre": "000_In_E1_Alta_Aut" },
    { "Id": 3, "Nombre": "000_IVR" }
  ],
  "truncated": false,
  "elapsedMs": 38
}
```

---

## Arquitectura

```mermaid
flowchart LR
  U[Usuario de negocio] --> C[Copilot Studio]
  C --> P[Power Automate]
  P --> T[Cloudflare Quick Tunnel<br/>https://*.trycloudflare.com]
  T --> A[MappingAgent.Api (.NET 8)<br/>localhost:5050]
  A --> D[(SQL Server MappingDW<br/>Docker local)]

  A --> V[/POST /api/sql/validate/]
  A --> Q[/POST /api/sql/query/]
  A --> H[/GET /health/]
```

Flujo:
- Copilot Studio llama acciones del Custom Connector.
- Power Automate invoca la API pública temporal por Cloudflare Tunnel.
- La API valida API key y barandas SQL, ejecuta `SELECT` en `MappingDW` y devuelve filas.
- SQL Server queda local en Docker y no se expone directamente a Internet.

---

## Quickstart

1. Copiar entorno:

```bash
cp .env.example .env
```

2. Editar `.env` (obligatorio):

```dotenv
MSSQL_SA_PASSWORD=TuPasswordFuerte123!
MAPPING_DB=MappingDW
MAPPING_DB_HOST=localhost
MAPPING_DB_PORT=1433
API_KEY=TuApiKeyLargaYPrivada
```

Qué hace cada variable:

- `MSSQL_SA_PASSWORD`: contraseña del usuario `sa` de SQL Server (la usa Docker y la API).
- `MAPPING_DB`: nombre de la base objetivo para consultas (`MappingDW`).
- `MAPPING_DB_HOST`: host donde corre SQL Server (`localhost` en local).
- `MAPPING_DB_PORT`: puerto de SQL Server (`1433`).
- `API_KEY`: clave requerida en header `X-API-Key` para `/api/sql/*`.

Recomendación:

- Usar valores fuertes en `MSSQL_SA_PASSWORD` y `API_KEY`.
- No subir `.env` al repositorio.

3. Levantar SQL:

```bash
docker compose --env-file .env -f infra/docker/docker-compose.dev.yml up -d
```

4. Crear esquema:

```bash
set -a; source .env; set +a
docker run --rm --network docker_default -v "$PWD/infra/docker/sql:/scripts:ro" \
  mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd \
  -S mappingagent-sql -U sa -P "$MSSQL_SA_PASSWORD" \
  -d master -i /scripts/001_create_schema.sql -b
```

5. Cargar seed o CSV:
- Seed: `infra/docker/sql/002_seed_demo.sql`
- CSV: `infra/docker/sql/003_import_data_csv.sql` (ver `data/README.md`)

6. Levantar API:

```bash
set -a; source .env; set +a
dotnet run --project src/MappingAgent.Api --urls http://127.0.0.1:5050
```

7. Probar:

```bash
curl http://127.0.0.1:5050/health
curl -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
  -d '{"sql":"SELECT TOP (1) 1 AS One"}' \
  http://127.0.0.1:5050/api/sql/validate
```

---

## Documentación detallada

- Deploy completo local/public demo: `docs/01-deployment-guide.md`
- Cloudflare quick tunnel sin dominio: `docs/02-cloudflare-tunnel.md`
- Copilot Studio + Power Automate paso a paso: `docs/03-copilot-power-automate-guide.md`
- Checklist para publicar en GitHub público: `docs/04-public-repo-checklist.md`
- OpenAPI para importar en Copilot: `docs/05-mappingdw-openapi.json`
- Estructura de CSV requeridos: `data/README.md`

---

## Estructura del proyecto (archivo por archivo)

## Raíz

- `MappingAgent.sln`
  - Solución .NET con API y tests.
- `.env.example`
  - Plantilla de variables (`MSSQL_SA_PASSWORD`, `MAPPING_DB_*`, `API_KEY`).
- `.env`
  - Variables locales reales (no versionar).
- `.gitignore`
  - Exclusión de secretos y CSV reales.
- `README.md`
  - Documento principal.

## `src/MappingAgent.Api`

- `Program.cs`
  - Minimal API completa: middleware API key, endpoints, validación SQL, ejecución Dapper.
- `MappingAgent.Api.csproj`
  - Dependencias del backend (`Dapper`, `Microsoft.Data.SqlClient`, `Swashbuckle`).
- `appsettings.json`
  - Configuración base.
- `appsettings.Development.json`
  - Overrides de desarrollo.
- `Properties/launchSettings.json`
  - Puertos de ejecución local (`5050` HTTP, `7050` HTTPS).

## `infra/docker`

- `docker-compose.dev.yml`
  - SQL Server local (`azure-sql-edge`) y volumen persistente.

## `infra/docker/sql`

- `001_create_schema.sql`
  - Crea DB `MappingDW`, tablas y claves foráneas.
- `002_seed_demo.sql`
  - Datos demo mínimos.
- `003_import_data_csv.sql`
  - Importación masiva de CSV reales.

## `data`

- `README.md`
  - Nombres requeridos de CSV y formato.
- `.gitkeep`
  - Mantener carpeta en repo.
- `*.csv` (solo local, no versionados)
  - Inputs reales para importar `MappingDW`.

## `scripts`

- `query-mapping.sh`
  - Consulta rápida contra `dbo.Mapping`.
- `run-tests.sh`
  - Ejecuta `dotnet build` + `dotnet test`.
- `run-tunnel.sh`
  - Levanta quick tunnel `trycloudflare` para `localhost:<puerto>`.

## `tests/MappingAgent.Api.Tests`

- `MappingAgent.Api.Tests.csproj`
  - Proyecto de tests xUnit.
- `ApiEndpointsTests.cs`
  - Pruebas de endpoints, auth y contrato Swagger/OpenAPI.

## `docs`

- `01-deployment-guide.md`
  - Setup total paso a paso.
- `02-cloudflare-tunnel.md`
  - Exposición pública temporal.
- `03-copilot-power-automate-guide.md`
  - Integración de Copilot Studio y Power Automate.
- `04-public-repo-checklist.md`
  - Checklist de publicación pública segura.
- `05-mappingdw-openapi.json`
  - Especificación OpenAPI actual de la API.

---

## Seguridad y alcance

- La base SQL no se expone directamente.
- La API exige `X-API-Key` para endpoints de negocio.
- SQL libre con barandas:
  - solo `SELECT` / `WITH`
  - sin `;`
  - bloqueo de keywords de escritura/DDL
  - límite automático `TOP (200)` si no hay paginación/límite explícito

---

## Tests

```bash
scripts/run-tests.sh
```

---

## Licencia

Definir según política interna antes de publicar.
