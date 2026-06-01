#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"
# shellcheck source=lib/docker.sh
source "${ROOT}/scripts/lib/docker.sh"

cd "$ROOT"
zeiron_load_env "$ROOT"

GRADIO_PORT="${GRADIO_PORT:-7860}"
API_PORT="${API_PORT:-8080}"
FAIL=0

check() {
  if "$@"; then
    echo "[ok] $*"
  else
    echo "[fail] $*"
    FAIL=1
  fi
}

echo "=== Zeiron Fish Speech validation ==="

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
  echo "[warn] nvidia-smi not found"
fi

check test -f "checkpoints/openaudio-s1-mini/codec.pth"
check test -d "outputs/fish-speech"

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    echo "[ok] Docker daemon running"
    zeiron_check_gpu_in_docker || FAIL=1
  else
    echo "[fail] Docker daemon not running"
    echo "       ${DOCKER_DESKTOP_MSG}"
    FAIL=1
  fi
else
  echo "[fail] docker not installed"
  FAIL=1
fi

if zeiron_resolve_compose; then
  echo "[ok] Docker Compose: ${COMPOSE_CMD}"
else
  echo "[fail] Docker Compose not available"
  FAIL=1
fi

if curl -sf "http://127.0.0.1:${GRADIO_PORT}/" >/dev/null 2>&1; then
  echo "[ok] WebUI http://127.0.0.1:${GRADIO_PORT}/"
else
  echo "[skip] WebUI not running"
fi

if curl -sf "http://127.0.0.1:${API_PORT}/docs" >/dev/null 2>&1; then
  echo "[ok] API http://127.0.0.1:${API_PORT}/docs"
else
  echo "[skip] API not running"
fi

[[ $FAIL -eq 0 ]] || exit 1
echo "=== Validation complete ==="
