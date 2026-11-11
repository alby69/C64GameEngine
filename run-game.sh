#!/usr/bin/env bash
# C64 GAME ENGINE - gioca al gioco nel simulatore VICE
# Auto-detects OS and runs the game (Linux/macOS or Windows)
set -euo pipefail

# Determine script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

# Detect operating system
OS="$(uname -s)"
case "${OS}" in
    Linux*|Darwin*)
        # Linux or macOS - use the Linux bin script
        exec "${PROJECT_ROOT}/bin/linux/run-game.sh" "$@"
        ;;
    *)
        # Fallback for unknown OS
        err "Sistema operativo non supportato: ${OS}"
        exit 1
        ;;
esac