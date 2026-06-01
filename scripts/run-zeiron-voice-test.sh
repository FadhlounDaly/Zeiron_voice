#!/usr/bin/env bash
# Generate standard Zeiron test phrases via the Fish Speech API.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"

cd "$ROOT"
zeiron_load_env "$ROOT"

API_PORT="${API_PORT:-8080}"
VOICE_ID="${VOICE_ID:-voice_a}"
OUT_DIR="${ROOT}/outputs/fish-speech"
REF_WAV="${ROOT}/references/${VOICE_ID}/sample.wav"
REF_LAB="${ROOT}/references/${VOICE_ID}/sample.lab"
API_BASE="http://127.0.0.1:${API_PORT}"

command -v curl >/dev/null 2>&1 || zeiron_die "curl is required"
command -v python3 >/dev/null 2>&1 || zeiron_die "python3 is required"

[[ -f "$REF_WAV" ]] || zeiron_die "Missing ${REF_WAV}. Run: ./scripts/register-voice.sh ${VOICE_ID} /path/to/recording.wav"
[[ -f "$REF_LAB" ]] || zeiron_die "Missing ${REF_LAB}. Create it or rerun register-voice.sh"

mkdir -p "$OUT_DIR"

if ! curl -sf "${API_BASE}/" >/dev/null 2>&1; then
  zeiron_die "Fish Speech API is not running at ${API_BASE}. Run: ./scripts/bootstrap-fish-speech.sh --api"
fi

API_PORT="$API_PORT" VOICE_ID="$VOICE_ID" python3 - <<'PYIN'
import base64
import json
import os
import sys
import urllib.request
from pathlib import Path

root = Path('/home/zeiron/projects/zeiron')
api = 'http://127.0.0.1:' + os.environ.get('API_PORT', '8080')
voice_id = os.environ.get('VOICE_ID', 'voice_a')
out_dir = root / 'outputs' / 'fish-speech'
ref_wav = root / 'references' / voice_id / 'sample.wav'
ref_lab = root / 'references' / voice_id / 'sample.lab'

phrases = [
    'Good morning. System ingestion is healthy.',
    'There are two pending approvals waiting in the queue.',
    'Your scheduled study session starts in thirty minutes.',
]

ref_b64 = base64.b64encode(ref_wav.read_bytes()).decode('utf-8')
ref_text = ' '.join(ref_lab.read_text(encoding='utf-8').splitlines())

print(f"[zeiron] Generating {len(phrases)} phrases -> {out_dir}/")

for i, phrase in enumerate(phrases, start=1):
    slug = ''.join(c.lower() if c.isalnum() else '_' for c in phrase)
    while '__' in slug:
        slug = slug.replace('__', '_')
    slug = slug.strip('_')[:40]
    out = out_dir / f"{i}_{slug}.wav"

    payload = {
        'text': phrase,
        'reference_audio': ref_b64,
        'reference_text': ref_text,
        'format': 'wav',
    }
    req = urllib.request.Request(
        api + '/v1/tts',
        data=json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'},
        method='POST',
    )

    print(f"[zeiron] ({i}/{len(phrases)}) {phrase}")
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            data = resp.read()
            if resp.status != 200 or not data:
                raise RuntimeError(f"HTTP {resp.status}")
            out.write_bytes(data)
            print(f"[zeiron]   -> {out}")
    except Exception as e:
        if out.exists():
            out.unlink()
        print(f"[zeiron] ERROR: TTS request failed for phrase {i}: {e}")
        sys.exit(1)

print(f"\n[ok] Test outputs written to: {out_dir}")
for p in sorted(out_dir.glob('*.wav')):
    print(f" - {p.name} ({p.stat().st_size} bytes)")
PYIN
