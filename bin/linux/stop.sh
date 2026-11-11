#!/usr/bin/env bash
# C64GameEngine - stop the docker stack (Linux / macOS)
set -euo pipefail

# Determine project root (three levels up from this script, since it's in bin/linux/)
PROJECT_ROOT="$(cd "$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")" && pwd)"

# shellcheck source=./common.sh
source "${PROJECT_ROOT}/scripts/common.sh"

usage() {
    cat <<'EOF'
Usage: stop.sh [options]

Options:
  --dev         stop only the development stack
  --images     remove the local docker images as well
  --volumes    remove the docker volumes as well
  -h, --help   show this help
EOF
}

ONLY_DEV=0
REMOVE_IMAGES=0
REMOVE_VOLUMES=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dev)      ONLY_DEV=1; shift ;;
        --images)   REMOVE_IMAGES=1; shift ;;
        --volumes)  REMOVE_VOLUMES=1; shift ;;
        -h|--help)  usage; exit 0 ;;
        *) err "Opzione sconosciuta: $1"; usage; exit 1 ;;
    esac
done

cd "${PROJECT_ROOT}"
load_env
require_docker

COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"
COMPOSE_ARGS=(-f "${COMPOSE_FILE}" --profile dev)

if [ "${ONLY_DEV}" -eq 1 ]; then
    info "Arresto dello stack di SVILUPPO"
    DOWN_ARGS=(rm -s -f dev)
else
    info "Arresto di tutti gli stack Docker"
    DOWN_ARGS=(down --remove-orphans)
fi

if [ "${REMOVE_IMAGES}" -eq 1 ]; then
    DOWN_ARGS+=(--rmi local)
fi
if [ "${REMOVE_VOLUMES}" -eq 1 ]; then
    DOWN_ARGS+=(--volumes)
fi

compose "${COMPOSE_ARGS[@]}" "${DOWN_ARGS[@]}"

ok "Stack Docker arrestato."