# Fish Speech — Setup & Prerequisites

Proof-of-concept reference for self-hosted [Fish Speech](https://github.com/fishaudio/fish-speech) (Fish Audio) as Zeiron’s voice layer. This document covers Phase 1: environment, hardware, and deployment options.

## Repository & Documentation

| Resource | URL |
|----------|-----|
| Source | https://github.com/fishaudio/fish-speech |
| Self-hosting (Docker) | https://docs.fish.audio/developer-guide/self-hosting/docker-deployment |
| Running inference | https://docs.fish.audio/developer-guide/self-hosting/running-inference |
| Voice cloning best practices | https://docs.fish.audio/developer-guide/best-practices/voice-cloning |
| Doc index (for agents) | https://docs.fish.audio/llms.txt |

## Recommended Deployment Method

For this POC, use **official pre-built Docker images** from Docker Hub (`fishaudio/fish-speech`). They are maintained by Fish Audio, bundle WebUI and API server targets, and match the upstream `compose.yml` layout.

| Profile | Image tag | Port | Use case |
|---------|-----------|------|----------|
| WebUI (GPU) | `webui-cuda-v2.0.0-beta` (RTX 50xx / Blackwell) or `webui-cuda` | 7860 | Interactive cloning & listening tests |
| API server (GPU) | `server-cuda-v2.0.0-beta` or `server-cuda` | 8080 | Zeiron/Harmony integration prototyping |
| WebUI (CPU) | `fishaudio/fish-speech:latest-webui-cpu` | 7860 | Smoke tests only (very slow) |
| API server (CPU) | `fishaudio/fish-speech:latest-server-cpu` | 8080 | CI-less validation without GPU |

**Model for local POC:** `openaudio-s1-mini` (0.5B, open weights on Hugging Face). This is the model the Docker images and docs assume by default. Full **S2-Pro** (4B) is documented in the repo but targets **24 GB+ VRAM**; it is not the default for this POC.

```bash
# Download weights (host, before first container start)
pip install -U "huggingface_hub[cli]"
huggingface-cli download fishaudio/openaudio-s1-mini --local-dir checkpoints/openaudio-s1-mini
```

Weights land in `./checkpoints/openaudio-s1-mini` (mounted into the container at `/app/checkpoints`).

## GPU Requirements

| Component | Requirement |
|-----------|-------------|
| Vendor | NVIDIA only for CUDA images |
| Driver | Recent NVIDIA driver (WSL2: Windows host driver + WSL GPU support) |
| Container runtime | [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) |
| VRAM (S1-mini, official Docker docs) | **≥ 12 GB** recommended for CUDA inference |
| VRAM (S2-Pro, upstream inference docs) | **≥ 24 GB** recommended for bf16 |

### This workstation (Zeiron dev, Jun 2026)

Detected during POC setup:

- **GPU:** NVIDIA GeForce RTX 5060 Ti — **16 GB VRAM**
- **CUDA (driver report):** UMD 13.3
- **Verdict:** Suitable for **S1-mini** POC and XTTS-v2 comparison. **S2-Pro** would require quantization or a larger GPU; not used in this POC.

## CUDA Requirements

| Layer | Version / notes |
|-------|-----------------|
| Docker CUDA base (upstream build args) | CUDA **12.6.0** default; repo also documents **12.9.0** with `UV_EXTRA=cu129` |
| PyTorch extra (native install) | `cu126`, `cu128`, or `cu129` via `pip install -e .[cu129]` |
| CPU fallback | `BACKEND=cpu` or CPU image tags — no CUDA required |

Verify GPU inside Docker:

```bash
docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi
```

## VRAM & Performance Notes

| Setting | Effect |
|---------|--------|
| `COMPILE=1` | Enables `torch.compile`; ~10× faster after warm-up (CUDA only) |
| `--half` / fp16 | Use on GPUs without bf16 support; lowers memory |
| Reference length | 10–30 s recommended; longer samples improve stability |
| Text length | Very long inputs increase peak VRAM |

Rough expectations (community / docs, not Zeiron benchmarks):

- **S1-mini on 12–16 GB:** Interactive POC is practical with `COMPILE=1`.
- **S2-Pro on 24 GB:** Near real-time on high-end cards; 12–16 GB needs FP8/NF4 quantization (not in this POC).

## Software Prerequisites

### Host (Linux / WSL2)

- Docker Engine 24+ (Docker Desktop with **WSL integration enabled** on WSL2)
- Docker Compose v2 (`docker compose`) *or* standalone `docker-compose`
- NVIDIA driver + Container Toolkit
- ~15 GB disk for S1-mini weights + generated audio
- `curl`, `ffmpeg` (optional, for sample prep)
- Hugging Face CLI for model download

### WSL2-specific

1. Install Docker Desktop on Windows.
2. Settings → Resources → WSL Integration → enable for your distro.
3. Confirm: `docker ps` works inside WSL (not only `docker --version`).
4. GPU passthrough: `nvidia-smi` in WSL **and** in a `--gpus all` container.

If `docker ps` fails with `docker.sock` missing, the daemon is not running — start Docker Desktop before Phase 2 validation.

## Directory Layout (POC)

```
zeiron/
├── checkpoints/          # Hugging Face weights (gitignored)
├── references/           # Voice profiles: <id>/sample.wav + sample.lab
├── outputs/fish-speech/  # Generated WAVs from test scripts
├── docker-compose.yml
├── docker-compose.xtts.yml   # Optional XTTS-v2 baseline
└── scripts/
    ├── bootstrap-fish-speech.sh   # Main entry — setup + start
    ├── register-voice.sh
    └── run-zeiron-voice-test.sh
```

## Automated bootstrap

```bash
./scripts/bootstrap-fish-speech.sh --webui   # default
./scripts/bootstrap-fish-speech.sh --api
```

Handles `.env` creation, model download, Docker checks, and service startup. See [README.md](../../README.md).

## Environment Variables (Fish Speech)

| Variable | Default | Description |
|----------|---------|-------------|
| `COMPILE` | `0` | Set `1` for torch.compile speedup |
| `BACKEND` | `cuda` | `cpu` for CPU images |
| `GRADIO_PORT` / WebUI | `7860` | WebUI port |
| `API_PORT` | `8080` | API server port |
| `LLAMA_CHECKPOINT_PATH` | `checkpoints/openaudio-s1-mini` | LLM weights |
| `DECODER_CHECKPOINT_PATH` | `.../codec.pth` | Codec weights |

Copy `.env.example` to `.env` and adjust.

## What We Are Not Using in This POC

- Fish Audio **cloud API** (requires API key; out of scope for “no cloud”)
- **S2-Pro** full-precision weights (VRAM)
- Fine-tuning / training pipelines
- Production Helm/K8s or Harmony wiring

## Next Steps

1. [README.md](../../README.md) — start Docker services and validate health.
2. [fish-speech-voice-cloning.md](./fish-speech-voice-cloning.md) — clone workflow and test phrases.
3. [fish-speech-zeiron-assessment.md](./fish-speech-zeiron-assessment.md) — Harmony integration sketch.
4. [fish-speech-vs-xtts.md](./fish-speech-vs-xtts.md) — side-by-side evaluation.
