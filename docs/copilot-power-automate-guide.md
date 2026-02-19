# Copilot Studio + Power Automate (step-by-step)

Esta guía explica cómo conectar la API de este repo a Copilot Studio usando OpenAPI y, opcionalmente, orquestarla con Power Automate.

## 1) Prerrequisitos

- API corriendo localmente en `http://127.0.0.1:5050`
- Quick tunnel activo (`https://<random>.trycloudflare.com`)
- `API_KEY` definida en `.env`
- Archivo OpenAPI: `docs/mappingdw-openapi.json`

## 2) Configurar Custom Connector en Copilot Studio

1. Abrir Copilot Studio.
2. Ir a **Tools** / **Plugins** / **Connectors** (según UI actual).
3. Crear un **Custom connector** desde OpenAPI.
4. Importar `docs/mappingdw-openapi.json`.
5. Configurar base URL:
   - `https://<random>.trycloudflare.com`
6. Configurar autenticación:
   - Header API key
   - Header name: `X-API-Key`
   - Value: `<tu API_KEY>`
7. Guardar y publicar el connector.

## 3) Operaciones sugeridas en Copilot

### A) Validar SQL antes de ejecutar

- Action: `POST /api/sql/validate`
- Body:
```json
{
  "sql": "<sql_generado_por_llm>"
}
```

Si `valid = false`, responder mensaje de error al usuario.

### B) Ejecutar SQL validado

- Action: `POST /api/sql/query`
- Body:
```json
{
  "question": "<pregunta original>",
  "sql": "<sql_generado_por_llm>",
  "params": {}
}
```

Copilot ya recibirá `rows` como array de records (compatible con tablas de Power Fx).

## 4) Variables recomendadas en Copilot

- `userQuestion` (string)
- `generatedSql` (string)
- `validationResult` (record)
- `queryResult` (record con `columns`, `rows`, `elapsedMs`)

## 5) Flujo recomendado del agente

1. Usuario pregunta en lenguaje natural.
2. Prompt LLM genera SQL solo lectura.
3. Llamar `/api/sql/validate`.
4. Si válido: llamar `/api/sql/query`.
5. Mostrar resultados (tabla + resumen de filas).

## 6) Power Automate (opcional)

Si preferís encapsular la lógica en un Flow:

1. Crear Cloud Flow (instant o callable).
2. Input: `question`.
3. Acción HTTP 1:
   - POST `https://<random>.trycloudflare.com/api/sql/validate`
   - Header `X-API-Key`
   - Body con SQL generado o recibido.
4. Condición:
   - Si `valid == false`, terminar con mensaje.
5. Acción HTTP 2:
   - POST `https://<random>.trycloudflare.com/api/sql/query`
   - Header `X-API-Key`
   - Body con `question`, `sql`, `params`.
6. Devolver respuesta al copiloto.

## 7) Ejemplo de llamada pública

```bash
curl -H "X-API-Key: <API_KEY>" \
     -H "Content-Type: application/json" \
     -d '{"question":"test","sql":"SELECT TOP (5) Id, Nombre FROM dbo.Mapping ORDER BY Id"}' \
     https://<random>.trycloudflare.com/api/sql/query
```

## 8) Troubleshooting

- `401 unauthorized`: API key incorrecta o faltante.
- `connection refused` en tunnel: API no está corriendo en el puerto objetivo.
- `PowerFxJsonException ... rows`: usar OpenAPI actualizado (`docs/mappingdw-openapi.json`) y verificar que `rows` sea array de objects.
- `database_unavailable` en `/health`: SQL no levantado o credenciales/env incorrectas.
