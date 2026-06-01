#!/usr/bin/env bash
# Download Fish Speech S1-mini weights from Hugging Face (no cloud inference).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECKPOINT="${ROOT}/checkpoints/openaudio-s1-mini"

cd "$ROOT"
mkdir -p checkpoints

if [[ -f "${CHECKPOINT}/codec.pth" ]]; then
  echo "[ok] Model already present at ${CHECKPOINT}"
  exit 0
fi

VENV="${ROOT}/.venv"
if [[ ! -d "$VENV" ]]; then
  echo "Creating Python venv at .venv ..."
  python3 -m venv "$VENV"
  "${VENV}/bin/pip" install -U "huggingface_hub[cli]"
fi
# shellcheck disable=SC1091
source "${VENV}/bin/activate"

if command -v hf >/dev/null 2>&1; then
  HF=hf
elif python3 -m huggingface_hub.cli.hf --help >/dev/null 2>&1; then
  HF="python3 -m huggingface_hub.cli.hf"
else
  echo "[error] Hugging Face CLI (hf) not found in venv"
  exit 1
fi

MODEL_REPO="${HF_MODEL_REPO:-fishaudio/openaudio-s1-mini}"

echo "Downloading ${MODEL_REPO} (~several GB)..."
set +e
DOWNLOAD_LOG="$($HF download "${MODEL_REPO}" --local-dir "${CHECKPOINT}" 2>&1)"
DOWNLOAD_STATUS=$?
set -e

if [[ $DOWNLOAD_STATUS -ne 0 ]]; then
  if echo "$DOWNLOAD_LOG" | grep -qiE 'access denied|gated|authenticate|401|403'; then
    cat <<EOF >&2

[error] Cannot download gated model: ${MODEL_REPO}

This model requires a Hugging Face account with accepted access.

1. Open https://huggingface.co/${MODEL_REPO}
2. Log in and click "Agree" to accept the license / request access
3. Create a token: https://huggingface.co/settings/tokens
4. Authenticate this machine:

     cd ${ROOT}
     source .venv/bin/activate
     hf auth login
     # or: export HF_TOKEN=hf_...

5. Rerun: ./scripts/bootstrap-fish-speech.sh --webui

EOF
    exit 1
  fi
  echo "$DOWNLOAD_LOG" >&2
  exit "$DOWNLOAD_STATUS"
fi

echo "[ok] Weights saved to ${CHECKPOINT}"
