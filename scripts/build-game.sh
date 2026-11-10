#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# C64 GAME ENGINE - build del gioco (Linux / macOS)
#
#   ./scripts/build-game.sh              compila con ACME (se installato)
#   ./scripts/build-game.sh --docker     compila dentro Docker
#   ./scripts/build-game.sh --test       compila e lancia i test automatici
#   ./scripts/build-game.sh --game hello compila un altro gioco
# ---------------------------------------------------------------------------
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

GAME="${GAME:-space-invaders}"
MODE="local"
TEST=0

while [ $# -gt 0 ]; do
    case "$1" in
        --docker) MODE="docker"; shift ;;
        --test)   TEST=1; shift ;;
        --game|-g)
            GAME="${2:-}"
            shift 2
            ;;
        -h|--help)
            printf "Usage: scripts/build-game.sh [--docker] [--test] [--game <nome>]\n"
            exit 0
            ;;
        *)
            err "Opzione sconosciuta: $1"
            exit 1
            ;;
    esac
done

cd "${PROJECT_ROOT}"

GAME_FILE="$(echo "${GAME}" | tr '-' '_')"
TARGET="games/${GAME}/${GAME_FILE}.prg"
SYMBOLS="games/${GAME}/${GAME_FILE}.symbols"

# Convenzione: il file principale e' l'unico "*_main.asm" della cartella
MAIN="$(basename "$(ls games/${GAME}/*_main.asm 2>/dev/null | head -1)")"
if [ -z "${MAIN}" ]; then
    err "Nessun file '*_main.asm' trovato in games/${GAME}."
    exit 1
fi

if [ "${MODE}" = "docker" ]; then
    require_docker
    info "Compilazione di '${GAME}' dentro Docker (ACME)"
    docker compose --profile build run --rm -e GAME="${GAME}" -e MAIN="${MAIN}" assembler
    ok "Compilato: ${TARGET}"
else
    if ! command -v acme >/dev/null 2>&1; then
        warn "ACME non trovato nel PATH: uso la compilazione dentro Docker."
        require_docker
        docker compose --profile build run --rm -e GAME="${GAME}" -e MAIN="${MAIN}" assembler
        ok "Compilato: ${TARGET}"
    else
        info "Compilazione di '${GAME}' con ACME"
        acme -f cbm -o "${TARGET}" -l "${SYMBOLS}" \
            -I engine -I "games/${GAME}" "games/${GAME}/${MAIN}"
        ok "Compilato: ${TARGET}"
    fi
fi

if [ "${TEST}" -eq 1 ]; then
    if command -v python3 >/dev/null 2>&1; then
        info "Esecuzione dei test automatici"
        python3 tools/c64test.py "${TARGET}" "${SYMBOLS}"
    else
        warn "python3 non trovato: test saltati."
    fi
fi
