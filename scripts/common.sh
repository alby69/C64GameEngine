#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# C64GameEngine - shared helpers (bash / Linux & macOS)
# ---------------------------------------------------------------------------

# shellcheck disable=SC2034
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [ -t 1 ]; then
    C_RESET=$'\033[0m'
    C_INFO=$'\033[36m'
    C_OK=$'\033[32m'
    C_WARN=$'\033[33m'
    C_ERR=$'\033[31m'
else
    C_RESET="" C_INFO="" C_OK="" C_WARN="" C_ERR=""
fi

info() { printf "%b\n" "${C_INFO}[INFO]${C_RESET} $*"; }
ok()   { printf "%b\n" "${C_OK}[ OK ]${C_RESET} $*"; }
warn() { printf "%b\n" "${C_WARN}[WARN]${C_RESET} $*"; }
err()  { printf "%b\n" "${C_ERR}[FAIL]${C_RESET} $*" >&2; }

# Load the variables of the .env file (if present) into the environment.
load_env() {
    local env_file="${PROJECT_ROOT}/.env"
    if [ -f "${env_file}" ]; then
        set -a
        # shellcheck disable=SC1090
        . "${env_file}"
        set +a
    fi
}

require_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        err "Docker non e' installato: https://docs.docker.com/get-docker/"
        exit 1
    fi
    if ! docker info >/dev/null 2>&1; then
        err "Docker daemon non raggiungibile. Avvia Docker e riprova."
        exit 1
    fi
}

# Run "docker compose" (v2) falling back to the legacy "docker-compose" (v1).
compose() {
    if docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    elif command -v docker-compose >/dev/null 2>&1; then
        docker-compose "$@"
    else
        err "Docker Compose non trovato."
        exit 1
    fi
}

# Wait until the container reports the given health status (or "running").
wait_for_container() {
    local container="$1"
    local timeout="${2:-90}"
    local elapsed=0
    local status=""

    while [ "${elapsed}" -lt "${timeout}" ]; do
        if ! docker inspect -f '{{.State.Status}}' "${container}" >/dev/null 2>&1; then
            sleep 2
            elapsed=$((elapsed + 2))
            continue
        fi
        status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "${container}" 2>/dev/null || echo "unknown")"
        case "${status}" in
            healthy|running) return 0 ;;
            exited|dead)    err "Il container '${container}' si e' fermato con stato '${status}'."; return 1 ;;
        esac
        sleep 2
        elapsed=$((elapsed + 2))
    done
    warn "Timeout (${timeout}s) in attesa del container '${container}' (stato: ${status})."
    return 1
}
