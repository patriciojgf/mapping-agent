# Cloudflare Tunnel (Quick Tunnel, sin dominio)

Este documento explica cómo exponer la API local a internet con una URL temporal `trycloudflare.com`, sin DNS propio y sin login.

## Requisitos

- API corriendo localmente en HTTP (`http://localhost:5050`)
- `cloudflared` instalado

## Instalar cloudflared en macOS

```bash
brew install cloudflared
```

Verificar instalación:

```bash
cloudflared --version
```

## Ejecutar quick tunnel

```bash
cloudflared tunnel --url http://localhost:5050
```

Cuando inicia, `cloudflared` imprime una URL pública similar a:

`https://random-subdomain.trycloudflare.com`

Esa URL es temporal.

## Verificar endpoint público

```bash
curl https://<trycloudflare>/health
```

Respuesta esperada:

```json
{"ok":true}
```

## Llamar endpoint protegido con API key

```bash
curl -H "X-API-Key: <API_KEY>" \
     -H "Content-Type: application/json" \
     -d '{"sql":"SELECT TOP (1) 1 AS One"}' \
     https://<trycloudflare>/api/sql/validate
```

## Ejemplo para `query`

```bash
curl -H "X-API-Key: <API_KEY>" \
     -H "Content-Type: application/json" \
     -d '{"question":"test","sql":"SELECT TOP (5) Id, Nombre FROM dbo.Mapping ORDER BY Id"}' \
     https://<trycloudflare>/api/sql/query
```
