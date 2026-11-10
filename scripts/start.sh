#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# C64GameEngine - start the docker stack
#
#   ./scripts/start.sh              production stack (nginx)  -> http://localhost:3000
#   ./scripts/start.sh --dev        development stack (vite)  -> http://localhost:3001
#   ./scripts/start.sh --no-build   reuse the existing image
#   ./scripts/start.sh --foreground attach to the logs
# ---------------------------------------------------------------------------
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

usage() {
    cat <<'EOF'
Usage: scripts/start.sh [options]

Options:
  -d, --dev          start the development stack (vite dev server + hot reload)
      --no-build     do not rebuild the images
  -f, --foreground   follow the container logs (default: detached)
  -h, --help         show this help
EOF
}

MODE="prod"
BUILD=1
FOREGROUND=0

while [ $# -gt 0 ]; do
    case "$1" in
        -d|--dev)        MODE="dev"; shift ;;
        --no-build)      BUILD=0; shift ;;
        -f|--foreground) FOREGROUND=1; shift ;;
        -h|--help)       usage; exit 0 ;;
        *) err "Opzione sconosciuta: $1"; usage; exit 1 ;;
    esac
done

cd "${PROJECT_ROOT}"
load_env
require_docker

APP_PORT="${APP_PORT:-3000}"
DEV_PORT="${DEV_PORT:-3001}"
COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"

COMPOSE_ARGS=(-f "${COMPOSE_FILE}")
if [ "${MODE}" = "dev" ]; then
    COMPOSE_ARGS+=(--profile dev)
fi

if [ "${MODE}" = "dev" ]; then
    CONTAINER="c64gameengine-dev"
    SERVICE="dev"
    URL="http://localhost:${DEV_PORT}"
    info "Avvio dello stack di SVILUPPO (vite, hot reload)"
else
    CONTAINER="c64gameengine"
    SERVICE="app"
    URL="http://localhost:${APP_PORT}"
    info "Avvio dello stack di PRODUZIONE (nginx)"
fi

UP_ARGS=(up -d --remove-orphans "${SERVICE}")
if [ "${BUILD}" -eq 1 ]; then
    UP_ARGS+=(--build)
fi

info "docker compose ${COMPOSE_ARGS[*]} ${UP_ARGS[*]}"
compose "${COMPOSE_ARGS[@]}" "${UP_ARGS[@]}"

if [ "${FOREGROUND}" -eq 1 ]; then
    info "Log in tempo reale (Ctrl+C per interrompere)"
    compose "${COMPOSE_ARGS[@]}" logs -f
    exit 0
fi

info "Attesa del container '${CONTAINER}'..."
if wait_for_container "${CONTAINER}" 120; then
    ok "Container '${CONTAINER}' pronto."
else
    warn "Il container non risulta pronto: controlla i log con scripts/logs.sh"
fi

echo
ok "C64GameEngine e' online: ${URL}"
info "Log:      scripts/logs.sh"
info "Arresto:  scripts/stop.sh"
echo
