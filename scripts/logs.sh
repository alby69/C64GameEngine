#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# C64GameEngine - follow the docker logs
#
#   ./scripts/logs.sh          production stack
#   ./scripts/logs.sh --dev    development stack
# ---------------------------------------------------------------------------
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

MODE="prod"
while [ $# -gt 0 ]; do
    case "$1" in
        -d|--dev) MODE="dev"; shift ;;
        -h|--help) printf "Usage: scripts/logs.sh [--dev]\n"; exit 0 ;;
        *) err "Opzione sconosciuta: $1"; exit 1 ;;
    esac
done

cd "${PROJECT_ROOT}"
load_env
require_docker

COMPOSE_ARGS=(-f "${PROJECT_ROOT}/docker-compose.yml" --profile dev)
if [ "${MODE}" = "dev" ]; then
    compose "${COMPOSE_ARGS[@]}" logs -f dev
else
    compose "${COMPOSE_ARGS[@]}" logs -f app
fi
