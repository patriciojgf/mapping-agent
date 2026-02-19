#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCH_SETTINGS="$ROOT_DIR/src/MappingAgent.Api/Properties/launchSettings.json"

detect_port_from_launch_settings() {
  if [[ -f "$LAUNCH_SETTINGS" ]]; then
    local port
    port="$(grep -E '"applicationUrl"' "$LAUNCH_SETTINGS" | grep -Eo 'http://localhost:[0-9]+' | head -n1 | sed -E 's#http://localhost:##')"
    if [[ -n "${port:-}" ]]; then
      echo "$port"
      return 0
    fi
  fi
  return 1
}

PORT="${1:-}"
if [[ -z "${PORT}" ]]; then
  if ! PORT="$(detect_port_from_launch_settings)"; then
    PORT="5050"
  fi
fi

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared no está instalado."
  echo "Instalalo con: brew install cloudflared"
  exit 1
fi

echo "Iniciando quick tunnel para http://localhost:${PORT}"
echo "Cuando aparezca la URL https://*.trycloudflare.com usala como base URL pública."

cloudflared tunnel --url "http://localhost:${PORT}" 2>&1 | while IFS= read -r line; do
  echo "$line"
  if [[ "$line" =~ https://[a-zA-Z0-9.-]+\.trycloudflare\.com ]]; then
    echo ""
    echo "URL pública detectada: ${BASH_REMATCH[0]}"
    echo "Probar health: curl ${BASH_REMATCH[0]}/health"
    echo ""
  fi
done
