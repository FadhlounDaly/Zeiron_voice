#!/usr/bin/env bash
# Build Fish Speech WebUI/API images for openaudio-s1-mini on CUDA 12.9 (RTX 50xx / Blackwell).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT}/scripts/lib/common.sh"
# shellcheck source=lib/docker.sh
source "${ROOT}/scripts/lib/docker.sh"

TARGET="${1:-webui}" # webui | server | both
REF="${FISH_SPEECH_GIT_REF:-781bf1c}"
CUDA_VER="${FISH_SPEECH_CUDA_VER:-12.9.0}"
UV_EXTRA="${FISH_SPEECH_UV_EXTRA:-cu129}"
CLONE_DIR="${ROOT}/.cache/fish-speech-src"
WEBUI_TAG="${FISH_SPEECH_WEBUI_IMAGE:-zeiron/fish-speech:webui-s1-cu129}"
API_TAG="${FISH_SPEECH_API_IMAGE:-zeiron/fish-speech:server-s1-cu129}"

zeiron_require_docker_daemon

mkdir -p "${ROOT}/.cache"
if [[ ! -d "${CLONE_DIR}/.git" ]]; then
  zeiron_log "Cloning fish-speech (checkout ${REF}) ..."
  git clone https://github.com/fishaudio/fish-speech.git "${CLONE_DIR}"
fi

cd "${CLONE_DIR}"
git fetch origin
git checkout "${REF}" 2>/dev/null || zeiron_die "Cannot checkout ref ${REF}"

build_one() {
  local docker_target="$1" tag="$2"
  zeiron_log "Building ${tag} (target=${docker_target}, CUDA ${CUDA_VER}, ${UV_EXTRA}) ..."
  docker build \
    --platform linux/amd64 \
    -f docker/Dockerfile \
    --build-arg BACKEND=cuda \
    --build-arg CUDA_VER="${CUDA_VER}" \
    --build-arg UV_EXTRA="${UV_EXTRA}" \
    --target "${docker_target}" \
    -t "${tag}" \
    .
}

case "$TARGET" in
  webui)  build_one webui "${WEBUI_TAG}" ;;
  server) build_one server "${API_TAG}" ;;
  both)
    build_one webui "${WEBUI_TAG}"
    build_one server "${API_TAG}"
    ;;
  *) zeiron_die "Usage: $0 [webui|server|both]" ;;
esac

zeiron_log "Build complete."
