# Docker / Compose helpers for Zeiron Fish Speech scripts.
# shellcheck shell=bash

DOCKER_DESKTOP_MSG='Docker Desktop is installed but not running or WSL integration is disabled. Start Docker Desktop, enable WSL integration for this distro, then rerun this script.'

zeiron_require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    zeiron_die "Docker is not installed. Install Docker Desktop and rerun."
  fi
}

zeiron_require_docker_daemon() {
  zeiron_require_docker
  if ! docker info >/dev/null 2>&1; then
    zeiron_die "$DOCKER_DESKTOP_MSG"
  fi
}

# Sets COMPOSE_CMD to a working compose command array name (exported as string).
zeiron_resolve_compose() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
    return 0
  fi
  if command -v docker-compose >/dev/null 2>&1 && docker-compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
    return 0
  fi
  return 1
}

zeiron_require_compose() {
  if zeiron_resolve_compose; then
    zeiron_log "Docker Compose: ${COMPOSE_CMD}"
    return 0
  fi
  zeiron_die "Docker Compose is not available. Install the Compose plugin (docker compose) or docker-compose, then rerun."
}

zeiron_compose() {
  # Usage: zeiron_compose <root> <profile> up -d
  local root="$1"
  shift
  (cd "$root" && eval "$COMPOSE_CMD $*")
}

zeiron_stop_other_profile() {
  local root="$1" keep="$2"
  if [[ "$keep" == "webui" ]]; then
    zeiron_compose "$root" --profile api down 2>/dev/null || true
  else
    zeiron_compose "$root" --profile webui down 2>/dev/null || true
  fi
}

zeiron_wait_http() {
  local url="$1" label="$2" max_secs="${3:-900}"
  local elapsed=0
  zeiron_log "Waiting for ${label} (${url}) — first start can take 10–15 min ..."
  while (( elapsed < max_secs )); do
    if docker logs "$label" 2>&1 | tail -30 | grep -qE 'no kernel image is available|CUDA error'; then
      zeiron_die "CUDA kernel mismatch. Rerun bootstrap to build zeiron/fish-speech:*-s1-cu129. Logs: docker logs ${label}"
    fi
    if docker logs "$label" 2>&1 | tail -30 | grep -qE 'UnboundLocalError.*tokenizer|Failed to load tokenizer'; then
      zeiron_die "Tokenizer/model mismatch: use openaudio-s1-mini with zeiron/fish-speech:*-s1-cu129 (not v2.0.0-beta S2 images). Logs: docker logs ${label}"
    fi
    if curl -sf "$url" >/dev/null 2>&1; then
      zeiron_log "${label} is ready"
      return 0
    fi
    sleep 10
    elapsed=$((elapsed + 10))
  done
  zeiron_die "${label} did not become ready within ${max_secs}s. Check: docker logs ${label}"
}

zeiron_gpu_needs_cu129_build() {
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    return 1
  fi
  local cap
  cap="$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 | tr -d ' ')"
  # Blackwell (RTX 50xx) is compute capability 12.x
  [[ "$cap" == 12.* ]]
}

zeiron_ensure_fish_speech_image() {
  local mode="$1" # webui | api
  local root="$2"
  local image

  if [[ "$mode" == "webui" ]]; then
    image="${FISH_SPEECH_WEBUI_IMAGE:-}"
    if [[ -z "$image" ]]; then
      if zeiron_gpu_needs_cu129_build; then
        image="zeiron/fish-speech:webui-s1-cu129"
      else
        image="fishaudio/fish-speech:webui-cuda"
      fi
      export FISH_SPEECH_WEBUI_IMAGE="$image"
    fi
  else
    image="${FISH_SPEECH_API_IMAGE:-}"
    if [[ -z "$image" ]]; then
      if zeiron_gpu_needs_cu129_build; then
        image="zeiron/fish-speech:server-s1-cu129"
      else
        image="fishaudio/fish-speech:server-cuda"
      fi
      export FISH_SPEECH_API_IMAGE="$image"
    fi
  fi

  if docker image inspect "$image" >/dev/null 2>&1; then
    zeiron_log "Using image: ${image}"
    return 0
  fi

  if [[ "$image" == zeiron/fish-speech:* ]]; then
    zeiron_log "Local CUDA 12.9 image missing — building (first time, ~20–40 min) ..."
    local target="${mode}"
    [[ "$mode" == "api" ]] && target="server"
    "${root}/scripts/build-fish-speech-image.sh" "$target"
    return 0
  fi

  zeiron_log "Pulling ${image} ..."
  docker pull "$image"
}

zeiron_check_gpu_in_docker() {
  if docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi >/dev/null 2>&1; then
    zeiron_log "GPU is visible inside Docker"
    return 0
  fi
  zeiron_log "WARN: GPU not visible in Docker — Fish Speech CUDA images may fail. Install NVIDIA Container Toolkit."
  return 1
}
