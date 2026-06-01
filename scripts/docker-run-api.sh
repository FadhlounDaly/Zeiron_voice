#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC1091
[[ -f "${ROOT}/.env" ]] && source "${ROOT}/.env"

PORT="${API_PORT:-8080}"
COMPILE="${COMPILE:-1}"

docker run -d \
  --name zeiron-fish-speech-api \
  --gpus all \
  -p "${PORT}:8080" \
  -v "${ROOT}/checkpoints:/app/checkpoints" \
  -v "${ROOT}/references:/app/references" \
  -v "${ROOT}/outputs:/app/outputs" \
  -e "COMPILE=${COMPILE}" \
  fishaudio/fish-speech:server-cuda

echo "API docs: http://127.0.0.1:${PORT}/docs"
