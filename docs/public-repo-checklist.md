# Public Repo Checklist

Checklist para publicar este proyecto en GitHub público sin exponer secretos ni datos.

## Seguridad

- [ ] Confirmar que `.env` NO está versionado.
- [ ] Confirmar que `data/*.csv` NO está versionado.
- [ ] Rotar `API_KEY` y `MSSQL_SA_PASSWORD` antes de demos públicas.
- [ ] No publicar URLs de tunnel activas.

## Contenido mínimo recomendado

- [x] `README.md`
- [x] `docs/deployment-guide.md`
- [x] `docs/copilot-power-automate-guide.md`
- [x] `docs/cloudflare-tunnel.md`
- [x] `docs/mappingdw-openapi.json`
- [x] `data/README.md` (sin datos reales)

## Verificación local antes de push

```bash
scripts/run-tests.sh
dotnet run --project src/MappingAgent.Api --urls http://127.0.0.1:5050
```

En otra terminal:

```bash
set -a; source .env; set +a
curl http://127.0.0.1:5050/health
curl -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
  -d '{"sql":"SELECT TOP (1) 1 AS One"}' \
  http://127.0.0.1:5050/api/sql/validate
```

## Estructura de datos esperada

Ver `data/README.md` para nombres exactos y formato requerido.
