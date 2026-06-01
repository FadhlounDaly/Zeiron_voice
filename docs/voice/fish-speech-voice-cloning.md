# Fish Speech — Voice Cloning Test (Phase 3)

Repeatable workflow for cloning a voice from a short recording and generating Zeiron-style announcement phrases.

## Inputs & outputs

| Item | Specification |
|------|----------------|
| **Input** | 30 s – 3 min clean speech, single speaker |
| **Profile** | `references/<voice_id>/sample.wav` + `sample.lab` |
| **Output (profile)** | Registered reference (no separate “model file” for S1-mini — timbre is encoded per request from reference) |
| **Output (audio)** | `outputs/fish-speech/*.wav` from test script or WebUI |

Fish Speech S1-mini uses **reference-audio cloning** at inference time: you do not train a persistent LoRA/checkpoint in this POC. The “cloned profile” is the `references/<id>/` pair mounted into the container.

## Cloning process

### A. Prepare reference (host)

```bash
./scripts/register-voice.sh chad /path/to/recording.wav
# Edit references/chad/sample.lab so it matches the audio exactly
```

Optional quality pass:

```bash
ffmpeg -i references/chad/sample.wav -af "highpass=f=80,lowpass=f=8000" references/chad/sample_clean.wav
mv references/chad/sample_clean.wav references/chad/sample.wav
```

### B. Register in WebUI (interactive)

1. Start WebUI: `./scripts/bootstrap-fish-speech.sh --webui`
2. Open the URL printed by the script (default http://localhost:7860)
3. Upload reference audio or select `chad` from the references library (if listed).
4. Enter / confirm **reference transcript** (matches `sample.lab`).
5. Enter target text → Generate → listen → download.

### C. Generate via API (automated)

1. Start API: `./scripts/bootstrap-fish-speech.sh --api` (stops WebUI automatically to free GPU).
2. Run:

```bash
./scripts/run-zeiron-voice-test.sh
```

### D. API request shape (manual)

Swagger at `/docs`. Typical JSON body:

```json
{
  "text": "Good morning Chad. Atlas ingestion is healthy.",
  "reference_audio": "<base64 wav>",
  "reference_text": "<transcript of reference>",
  "format": "wav"
}
```

## Test phrases (Zeiron copy)

| # | Text | Notes |
|---|------|-------|
| 1 | Good morning Chad. Atlas ingestion is healthy. | English, calm briefing tone |
| 2 | There are two pending approvals waiting in Bifrost. | English, slightly urgent |
| 3 | Your Japanese study session starts in thirty minutes. | English surface text; tests prosody on mixed context |

For Japanese **spoken** output, use Japanese script in `text` with a Japanese `sample.lab` / reference recording (see multilingual section in [fish-speech-zeiron-assessment.md](./fish-speech-zeiron-assessment.md)).

Stored in repo: [samples/test-phrases.txt](../../samples/test-phrases.txt)

## Required sample quality

| Factor | Requirement |
|--------|-------------|
| Duration | ≥ 30 s (60–120 s ideal) |
| Speakers | Exactly one |
| Noise | Minimal; no music/TV |
| Clipping | Avoid; normalize quietly if needed |
| Transcript | Must match audio; errors cause timbre drift |
| Emotion | Neutral–consistent; match desired output style |

Official guidance: https://docs.fish.audio/developer-guide/best-practices/voice-cloning

## Processing time (expectations)

Measured on **RTX 5060 Ti 16 GB** class hardware with **S1-mini** and `COMPILE=1` (fill in after first run):

| Stage | Typical duration |
|-------|------------------|
| Container cold start | 1–3 min (model load) |
| First generation (compile warm-up) | 2–5 min |
| Subsequent phrase (~1 sentence) | *Record RTF here* |
| WebUI auto-transcribe (if used) | +10–30 s |

Record actuals in the table below when you run the POC:

| Run | Reference length | Phrase | Wall time | Notes |
|-----|------------------|--------|-----------|-------|
| 1 | | Phrase 1 | | |
| 2 | | Phrase 2 | | | |
| 3 | | Phrase 3 | | |

## Output quality observations (template)

Listen with headphones. Score 1–5.

| Criterion | Score (1–5) | Notes |
|-----------|-------------|-------|
| Voice similarity | | |
| Naturalness | | |
| Prosody / pacing | | |
| Proper nouns (Chad, Atlas, Bifrost) | | |
| Emotional fit (briefing vs reminder) | | |
| Artifacts (robotic, metallic, breath) | | |

**Initial assessment (pre-listening, based on model class):**

- S1-mini is a **distilled** open model — expect strong clarity for POC, possibly less nuance than cloud S2-Pro or than XTTS on some voices.
- Accurate `sample.lab` is the highest-leverage quality knob.
- Emotion markers (S1 syntax) can be added for phrase 2: `(serious) There are two pending approvals waiting in Bifrost.`

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Robotic output | Short or mismatched reference | Longer sample; fix transcript |
| Wrong voice | Multiple speakers in sample | Re-record |
| CUDA OOM | WebUI + API both running | Stop one service |
| API 404/422 | Endpoint/version drift | Use `/docs` schema; fall back to WebUI |
| Docker.sock missing (WSL) | Docker Desktop stopped | Start Docker Desktop, enable WSL integration |

## Comparison run

Generate the same phrases with XTTS for Phase 5:

```bash
docker compose -f docker-compose.xtts.yml up -d
# XTTS has no automated test script in this kit — compare by ear
./scripts/compare-output.sh
```

See [fish-speech-vs-xtts.md](./fish-speech-vs-xtts.md).
