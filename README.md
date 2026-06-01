# Zeiron — Fish Speech Voice POC

Local evaluation kit for [Fish Speech](https://github.com/fishaudio/fish-speech). Automated scripts handle env setup, model download, Docker, and test generation. No cloud dependencies.

## Quick start

```bash
cd repo

# 1. Start WebUI (downloads weights on first run)
./scripts/bootstrap-fish-speech.sh --webui

# 2. Register your voice (30s–3min recording)
./scripts/register-voice.sh voice_a /path/to/recording.wav
# Edit references/voice_a/sample.lab so it matches the audio

# 3. Start API for automated tests (stops WebUI to free GPU)
./scripts/bootstrap-fish-speech.sh --api

# 4. Generate Zeiron test phrases
./scripts/run-zeiron-voice-test.sh
```

Listen to WAV files in `outputs/fish-speech/`.

Default bootstrap mode is WebUI if you omit the flag:

```bash
./scripts/bootstrap-fish-speech.sh
```

## Prerequisites

- **Docker Desktop** running with **WSL integration** enabled for this distro
- **NVIDIA GPU** with ≥ 12 GB VRAM (S1-mini)
- **jq** and **curl** for automated tests (`sudo apt install jq curl`)
- Optional: **ffmpeg** for audio conversion during voice registration

Details: [docs/voice/fish-speech-setup.md](docs/voice/fish-speech-setup.md)

## Scripts

| Script | Purpose |
|--------|---------|
| `bootstrap-fish-speech.sh` | Full setup + start `--webui` or `--api` |
| `register-voice.sh` | Add `references/<id>/sample.wav` + `sample.lab` |
| `run-zeiron-voice-test.sh` | Generate three standard phrases via API |

Internal helpers (called automatically): `download-models.sh`, `lib/docker.sh`, `lib/common.sh`.

Fallback if Compose plugin is missing: `scripts/docker-run-webui.sh`, `scripts/docker-run-api.sh` (not the main path).

## Test phrases

1. Good morning. System ingestion is healthy.
2. There are two pending approvals waiting in the queue.
3. Your scheduled study session starts in thirty minutes.

## Optional: XTTS comparison

```bash
docker compose -f docker-compose.xtts.yml up -d
# Manual listening test — see docs/voice/fish-speech-vs-xtts.md
```

## Documentation

| Document | Purpose |
|----------|---------|
| [fish-speech-setup.md](docs/voice/fish-speech-setup.md) | GPU, CUDA, VRAM |
| [fish-speech-voice-cloning.md](docs/voice/fish-speech-voice-cloning.md) | Cloning workflow |
| [fish-speech-zeiron-assessment.md](docs/voice/fish-speech-zeiron-assessment.md) | Harmony integration |
| [fish-speech-vs-xtts.md](docs/voice/fish-speech-vs-xtts.md) | Fish Speech vs XTTS-v2 |

## Stop services

```bash
docker compose --profile webui --profile api down
```

## Troubleshooting

If bootstrap fails immediately, start **Docker Desktop** and enable WSL integration, then rerun.

First API generation after `COMPILE=1` can take several minutes (torch.compile warm-up).
