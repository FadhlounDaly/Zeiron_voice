# Shared helpers for Zeiron Fish Speech scripts.
# shellcheck shell=bash

zeiron_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")/../.." && pwd)"
  echo "$script_dir"
}

zeiron_load_env() {
  local root="$1"
  # shellcheck disable=SC1091
  if [[ -f "${root}/.env" ]]; then
    set -a
    source "${root}/.env"
    set +a
  fi
}

zeiron_ensure_env_file() {
  local root="$1"
  if [[ ! -f "${root}/.env" ]]; then
    cp "${root}/.env.example" "${root}/.env"
    echo "[ok] Created .env from .env.example"
  fi
}

zeiron_ensure_dirs() {
  local root="$1"
  mkdir -p \
    "${root}/checkpoints" \
    "${root}/references" \
    "${root}/outputs/fish-speech" \
    "${root}/outputs/xtts"
}

zeiron_log() {
  echo "[zeiron] $*"
}

zeiron_die() {
  echo "[zeiron] ERROR: $*" >&2
  exit 1
}
