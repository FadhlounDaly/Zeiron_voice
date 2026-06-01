#!/usr/bin/env bash
# Fallback when 'docker compose' plugin is missing
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
[[ -f "${ROOT}/.env" ]] && source "${ROOT}/.env"

PORT="${GRADIO_PORT:-7860}"
COMPILE="${COMPILE:-1}"

docker run -d \
  --name zeiron-fish-speech-webui \
  --gpus all \
  -p "${PORT}:7860" \
  -v "${ROOT}/checkpoints:/app/checkpoints" \
  -v "${ROOT}/references:/app/references" \
  -e "COMPILE=${COMPILE}" \
  fishaudio/fish-speech:webui-cuda

echo "WebUI: http://127.0.0.1:${PORT}/"
