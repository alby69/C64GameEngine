#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# C64 GAME ENGINE - build del gioco (Linux / macOS)
#
#   ./scripts/build-game.sh              compila con ACME (se installato)
#   ./scripts/build-game.sh --docker     compila dentro Docker
#   ./scripts/build-game.sh --test       compila e lancia i test automatici
# ---------------------------------------------------------------------------
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

GAME="${GAME:-space-invaders}"
GAME_FILE="$(echo "${GAME}" | tr '-' '_')"
TARGET="games/${GAME}/${GAME_FILE}.prg"
MODE="local"
TEST=0

while [ $# -gt 0 ]; do
    case "$1" in
        --docker) MODE="docker"; shift ;;
        --test)   TEST=1; shift ;;
        -h|--help)
            printf "Usage: scripts/build-game.sh [--docker] [--test]\n"
            exit 0 ;;
        *) err "Opzione sconosciuta: $1"; exit 1 ;;
    esac
done

cd "${PROJECT_ROOT}"

if [ "${MODE}" = "docker" ]; then
    require_docker
    info "Compilazione di '${GAME}' dentro Docker (ACME)"
    docker compose --profile build run --rm assembler
    ok "Compilato: ${TARGET}"
else
    if ! command -v acme >/dev/null 2>&1; then
        warn "ACME non trovato nel PATH: uso la compilazione dentro Docker."
        MODE="docker"
        require_docker
        docker compose --profile build run --rm assembler
        ok "Compilato: ${TARGET}"
    else
        info "Compilazione di '${GAME}' con ACME"
        acme -f cbm -o "${TARGET}" -l symbols.txt \
            -I engine -I "games/${GAME}" "games/${GAME}/si_main.asm"
        ok "Compilato: ${TARGET}"
    fi
fi

if [ "${TEST}" -eq 1 ]; then
    if command -v python3 >/dev/null 2>&1; then
        info "Esecuzione dei test automatici"
        python3 tools/c64test.py "${TARGET}" symbols.txt
    else
        warn "python3 non trovato: test saltati."
    fi
fi
