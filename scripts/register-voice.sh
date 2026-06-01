#!/usr/bin/env bash
# Register a reference voice under references/<voice_id>/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

VOICE_ID="${1:-}"
SOURCE="${2:-}"

if [[ -z "$VOICE_ID" || -z "$SOURCE" ]]; then
  zeiron_die "Usage: $(basename "$0") <voice_id> <path-to-recording.wav>"
fi

if [[ ! -f "$SOURCE" ]]; then
  zeiron_die "Audio file not found: ${SOURCE}"
fi

DEST_DIR="${ROOT}/references/${VOICE_ID}"
mkdir -p "$DEST_DIR"

zeiron_log "Registering voice '${VOICE_ID}' ..."

if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -y -loglevel error -i "$SOURCE" -ar 44100 -ac 1 "${DEST_DIR}/sample.wav"
else
  cp "$SOURCE" "${DEST_DIR}/sample.wav"
  zeiron_log "ffmpeg not found — copied file as-is (WAV recommended)"
fi

CREATED_LAB=0
if [[ ! -f "${DEST_DIR}/sample.lab" ]]; then
  CREATED_LAB=1
  cat > "${DEST_DIR}/sample.lab" <<'EOF'
Hello, my name is Chad. I use Zeiron to stay on top of Atlas ingestion and Bifrost approvals.
EOF
fi

zeiron_ensure_dirs "$ROOT"

echo ""
echo "[ok] Voice registered: ${DEST_DIR}"
echo "     sample.wav  ($(du -h "${DEST_DIR}/sample.wav" | cut -f1))"
echo "     sample.lab"
echo ""

if [[ "$CREATED_LAB" -eq 1 ]]; then
  echo "IMPORTANT: Edit the transcript so it matches the recording exactly:"
  echo "  ${DEST_DIR}/sample.lab"
  echo ""
  echo "Automatic transcription is not run by this script. After starting the WebUI,"
  echo "you can transcribe there once, then paste the result into sample.lab."
  echo ""
else
  echo "sample.lab already exists — left unchanged."
  echo "Verify it still matches sample.wav before running tests."
  echo ""
fi

echo "Then:"
echo "  ./scripts/bootstrap-fish-speech.sh --api"
echo "  ./scripts/run-zeiron-voice-test.sh"
