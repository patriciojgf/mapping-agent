# Data Inputs (no versionar CSV reales)

Esta carpeta contiene los archivos CSV requeridos para poblar `MappingDW`.

## Regla de publicación

- En un repo público **no subir datos reales**.
- El `.gitignore` ya excluye `data/*.csv`.
- Mantener solo esta guía y `.gitkeep`.

## Archivos requeridos (nombres exactos)

- `Aplicacion.csv`
- `Columna.csv`
- `MainframeApp.csv`
- `ReglasModelado.csv`
- `RelacionJclMainframeApp.csv`
- `Sequence.csv`
- `TipoDato.csv`
- `TipoEsquema.csv`
- `TipoMotorBaseDeDatos.csv`
- `TipoServer.csv`
- `Transformacion.csv`
- `etl.csv`
- `jcl.csv`
- `mapping.csv`
- `tabla.csv`

Estos nombres están hardcodeados en:
- `infra/docker/sql/003_import_data_csv.sql`

## Formato esperado

- Delimitador de columnas: `;`
- Sin header
- UTF-8
- Fin de línea: CRLF
- Campos con comillas dobles permitidos
- `NULL` textual en `Transformacion.csv` para columnas nullable

## Mapeo de carga

El script `003_import_data_csv.sql` carga estos CSV contra `/var/opt/mssql/import/<archivo>.csv`.
Por eso, antes de ejecutar la importación hay que copiar los archivos al contenedor:

```bash
docker exec mappingagent-sql mkdir -p /var/opt/mssql/import
docker cp data/. mappingagent-sql:/var/opt/mssql/import/
```

Luego ejecutar:

```bash
docker run --rm --network docker_default -v "$PWD/infra/docker/sql:/scripts:ro" \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd \
  -S mappingagent-sql -U sa -P "$MSSQL_SA_PASSWORD" \
  -d master -i /scripts/003_import_data_csv.sql -b
```
