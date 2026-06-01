#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Fish Speech outputs:"
ls -la "${ROOT}/outputs/fish-speech/" 2>/dev/null || echo "  (none — run ./scripts/run-zeiron-voice-test.sh)"

echo ""
echo "XTTS outputs (optional):"
ls -la "${ROOT}/outputs/xtts/" 2>/dev/null || echo "  (none)"

echo ""
echo "Score listening tests: docs/voice/fish-speech-vs-xtts.md"
