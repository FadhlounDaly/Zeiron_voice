# Fish Speech vs XTTS-v2 — Comparison (Phase 5)

Side-by-side evaluation for Zeiron’s local voice layer. Both run offline via Docker in this POC.

| | Fish Speech (POC) | XTTS-v2 (POC) |
|---|-------------------|---------------|
| **Image** | `fishaudio/fish-speech:latest-*-cuda` | `ghcr.io/coqui-ai/tts:latest` |
| **Model** | OpenAudio S1-mini (0.5B) | `xtts_v2` multilingual |
| **Clone mechanism** | Reference audio + transcript | ~6 s reference, speaker_wav |
| **API port** | 8080 | 5002 |

## Evaluation criteria

Score after listening tests (**1 = poor, 5 = excellent**). Replace `—` with your scores.

| Criterion | Fish Speech (S1-mini) | XTTS-v2 | Notes |
|-----------|----------------------|---------|-------|
| **Voice similarity** | — | — | Same reference speaker for both |
| **Naturalness** | — | — | |
| **Emotional expression** | — | — | Fish: `(serious)` etc.; XTTS: limited inline control |
| **Latency** (wall time, phrase 1) | — s | — s | Record from `generate-test-phrases.sh` |
| **Resource usage (peak VRAM)** | ~8–12 GB est. | ~2–4 GB est. | `nvidia-smi` during run |
| **Ease of deployment** | Medium | Easier | XTTS single container; Fish needs HF weights |
| **Local execution suitability** | Good @ ≥12 GB | Excellent @ ≥8 GB | |
| **Proper nouns** | — | — | Project-specific entity names |
| **Japanese (native script)** | — | — | Requires JA reference + text |
| **French** | — | — | Requires FR reference + text |

## Dimensional analysis

### Voice similarity

| | Fish Speech | XTTS-v2 |
|---|-------------|---------|
| Strength | Strong timbre lock when transcript matches; multiple references possible | Fast zero-shot from short clip |
| Weakness | Sensitive to `sample.lab` accuracy | Can sound “filtered” or inconsistent on long phrases |
| Zeiron fit | Good for **fixed persona** (assistant voice) with one-time quality recording | Good for **quick experiments** |

### Naturalness & prosody

| | Fish Speech | XTTS-v2 |
|---|-------------|---------|
| Strength | Emotion/tone markers; strong on expressive English (S1) | Mature multilingual prosody for many locales |
| Weakness | S1-mini < cloud S2-Pro | Occasional robotic tail, chunk boundaries |
| Zeiron fit | Better for **briefings with tone** | Better for **straight informational** lines |

### Emotional expression

- **Fish Speech:** Documented emotion markers (English/Chinese/Japanese for S1); S2 uses bracket natural-language tags.
- **XTTS-v2:** Primarily neutral; emotion via reference audio style, not inline tags.

**Zeiron:** Prefer Fish if Harmony should map intent → `(calm)` / `(serious)` without re-recording.

### Latency

| Engine | Typical RTF (community) | POC target |
|--------|-------------------------|------------|
| Fish S1-mini + COMPILE | Interactive on 12–16 GB | Measure |
| XTTS-v2 FP16 | ~0.15 RTF (~4× real-time on mid GPU) | Often faster cold start |

XTTS usually wins **time-to-first-audio** on consumer GPUs. Fish catches up after compile warm-up on supported cards.

### Resource usage

| | Fish Speech S1-mini | XTTS-v2 |
|---|---------------------|---------|
| VRAM | 12 GB min (docs), ~8–12 GB practical | ~2–4 GB inference |
| Disk | ~several GB checkpoints | ~1.5 GB model cache volume |
| CPU fallback | Poor | Possible but slow |

On **16 GB** shared with a local LLM, XTTS leaves more headroom; Fish may require **exclusive GPU** during speech.

### Ease of deployment

| | Fish Speech | XTTS-v2 |
|---|-------------|---------|
| Setup | Download HF weights + CUDA image | Single `docker compose -f docker-compose.xtts.yml up` |
| Docs | Strong (fish.audio) | Community / Coqui legacy |
| API stability | Active upstream | Coqui org wind-down; community forks |

### Local execution suitability

Both satisfy **no cloud** when self-hosted.

| Requirement | Fish Speech | XTTS-v2 |
|-------------|-------------|---------|
| Offline | Yes | Yes |
| Reproducible | Pin image + weight hash | Pin image + model name |
| WSL2 + Docker Desktop | Yes (when daemon running) | Same |
| macOS native | Limited; Docker/WSL | Docker |

## Language-specific notes (Zeiron)

| Language | Fish Speech | XTTS-v2 |
|----------|-------------|---------|
| English | Primary POC path | Strong |
| Japanese | Use JA reference; phoneme docs available | `language=ja`, 17-lang model |
| French | Supported; FR reference recommended | `language=fr` |

XTTS is proven for **multilingual one model**. Fish cloud S2-Pro leads on expressiveness; **S1-mini** may trail XTTS on some JA/FR tests — validate by ear.

## Decision matrix (preliminary)

| Priority | Favor |
|----------|-------|
| Lowest VRAM / coexist with LLM | XTTS-v2 |
| Best persona lock + emotion | Fish Speech (consider S2-Pro later on 24 GB) |
| Fastest POC | XTTS-v2 |
| Long-term vendor/docs momentum | Fish Speech |
| Multilingual single container | XTTS-v2 |

**Suggested path for Zeiron:** Standardize Harmony on a **TTS adapter interface**; default implementation **Fish Speech API** for persona and emotion; **XTTS fallback** when GPU memory is constrained or Fish API is down.

## How to reproduce comparison

```bash
# Fish Speech
docker compose --profile api up -d
./scripts/generate-test-phrases.sh

# XTTS
docker compose -f docker-compose.xtts.yml up -d
./scripts/generate-test-phrases.sh --engine xtts

./scripts/compare-output.sh
```

Fill the score table above after listening on the same headphones/speaker.

## References

- Fish Speech: https://github.com/fishaudio/fish-speech
- Fish self-hosting: https://docs.fish.audio/developer-guide/self-hosting/docker-deployment
- Coqui XTTS: https://github.com/coqui-ai/TTS
- Zeiron setup: [fish-speech-setup.md](./fish-speech-setup.md)
