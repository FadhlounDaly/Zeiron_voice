#!/usr/bin/env bash
# One-command bootstrap: env, weights, validation, start WebUI or API.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"
# shellcheck source=lib/docker.sh
source "${ROOT}/scripts/lib/docker.sh"

MODE="webui"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--webui | --api]

  --webui   Start Gradio WebUI (default) — http://localhost:7860
  --api     Start HTTP API server — http://localhost:8080/

Prepares .env, downloads model weights, validates files, and starts Docker.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --webui) MODE="webui"; shift ;;
    --api)   MODE="api"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) zeiron_die "Unknown argument: $1 (use --webui or --api)" ;;
  esac
done

cd "$ROOT"

zeiron_log "Zeiron Fish Speech bootstrap (mode: ${MODE})"

# --- Docker ---
zeiron_require_docker_daemon
zeiron_require_compose
zeiron_check_gpu_in_docker || true

# --- Environment & layout ---
zeiron_ensure_env_file "$ROOT"
zeiron_load_env "$ROOT"
zeiron_ensure_dirs "$ROOT"

# --- Model weights ---
if [[ ! -f "${ROOT}/checkpoints/openaudio-s1-mini/codec.pth" ]]; then
  zeiron_log "Downloading model weights (first run may take several minutes) ..."
  "${ROOT}/scripts/download-models.sh"
else
  zeiron_log "Model weights already present"
fi

if [[ ! -f "${ROOT}/checkpoints/openaudio-s1-mini/codec.pth" ]]; then
  zeiron_die "Missing checkpoints/openaudio-s1-mini/codec.pth after download"
fi
zeiron_log "Validated model weights"

# --- Image: S1-mini + CUDA 12.9 on Blackwell; official webui-cuda elsewhere ---
zeiron_ensure_fish_speech_image "$MODE" "$ROOT"

# --- Start service (one GPU consumer at a time) ---
zeiron_stop_other_profile "$ROOT" "$MODE"

if [[ "$MODE" == "webui" ]]; then
  zeiron_compose "$ROOT" --profile webui up -d
  PORT="${GRADIO_PORT:-7860}"
  URL="http://127.0.0.1:${PORT}/"
  zeiron_wait_http "$URL" "zeiron-fish-speech-webui" "${BOOTSTRAP_WAIT_SECS:-900}"
else
  zeiron_compose "$ROOT" --profile api up -d
  PORT="${API_PORT:-8080}"
  URL="http://127.0.0.1:${PORT}/"
  zeiron_wait_http "$URL" "zeiron-fish-speech-api" "${BOOTSTRAP_WAIT_SECS:-900}"
fi

echo ""
echo "=============================================="
echo " Fish Speech is ready (${MODE})"
echo " URL: ${URL}"
echo "=============================================="
echo ""
if [[ "$MODE" == "webui" ]]; then
  echo "Next:"
  echo "  ./scripts/register-voice.sh voice_a /path/to/recording.wav"
  echo "  ./scripts/bootstrap-fish-speech.sh --api"
  echo "  ./scripts/run-zeiron-voice-test.sh"
else
  echo "Next:"
  echo "  ./scripts/run-zeiron-voice-test.sh"
fi
echo ""
