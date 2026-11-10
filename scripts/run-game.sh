#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# C64 GAME ENGINE - gioca al gioco nel simulatore VICE (Linux / macOS)
#
#   ./scripts/run-game.sh                 gioca a space-invaders
#   ./scripts/run-game.sh --game hello    gioca a un altro gioco
#   ./scripts/run-game.sh --emulator /percorso/x64
#
# Compila il gioco se serve e lo avvia dentro VICE.
# ---------------------------------------------------------------------------
set -euo pipefail

# shellcheck source=./common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

GAME="${GAME:-space-invaders}"
EMULATOR=""

while [ $# -gt 0 ]; do
    case "$1" in
        --game|-g)      GAME="${2:-}"; shift 2 ;;
        --emulator|-e)  EMULATOR="${2:-}"; shift 2 ;;
        -h|--help)
            printf "Usage: scripts/run-game.sh [--game <nome>] [--emulator <percorso>]\n"
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

# ---------------------------------------------------------------------------
# 1. Compila il gioco se il .prg non esiste
# ---------------------------------------------------------------------------
if [ ! -f "${TARGET}" ]; then
    info "Compilo '${GAME}' prima di avviarlo..."
    bash "${SCRIPT_DIR}/build-game.sh" --game "${GAME}"
fi

if [ ! -f "${TARGET}" ]; then
    err "File non trovato: ${TARGET}"
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Cerca il simulatore VICE
# ---------------------------------------------------------------------------
if [ -z "${EMULATOR}" ]; then
    for candidate in x64 x64sc vice; do
        if command -v "${candidate}" >/dev/null 2>&1; then
            EMULATOR="${candidate}"
            break
        fi
    done
fi

if [ -z "${EMULATOR}" ]; then
    for candidate in /usr/games/vice/x64 /usr/local/games/vice/x64 \
                     /Applications/vice/x64 /Applications/vice/x64-sdl; do
        if [ -x "${candidate}" ]; then
            EMULATOR="${candidate}"
            break
        fi
    done
fi

if [ -z "${EMULATOR}" ]; then
    echo
    err "VICE non trovato."
    echo
    echo "  Installalo:"
    echo "    Debian/Ubuntu : sudo apt install vice"
    echo "    Fedora        : sudo dnf install vice"
    echo "    Arch          : sudo pacman -S vice"
    echo "    macOS         : brew install vice"
    echo
    echo "  Oppure apri il file .prg con un qualsiasi emulatore C64:"
    echo "    ${PROJECT_ROOT}/${TARGET}"
    echo
    echo "  Emulatori alternativi: CCS64, Micro64, C64 Online, RetroArch."
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. Avvia il gioco
# ---------------------------------------------------------------------------
info "Avvio di '${GAME}' con ${EMULATOR}"
info "Per uscire dal simulatore: Ctrl+C"
echo
exec "${EMULATOR}" -autostartprgmode 1 "${PROJECT_ROOT}/${TARGET}"
