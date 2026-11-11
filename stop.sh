#!/usr/bin/env bash
# C64GameEngine - stop the docker stack
# Auto-detects OS and stops the appropriate stack (Linux/macOS or Windows)
set -euo pipefail

# Determine script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

# Detect operating system
OS="$(uname -s)"
case "${OS}" in
    Linux*|Darwin*)
        # Linux or macOS - use the Linux bin script
        exec "${PROJECT_ROOT}/bin/linux/stop.sh" "$@"
        ;;
    *)
        # Fallback for unknown OS (should not happen in practice)
        err "Sistema operativo non supportato: ${OS}"
        exit 1
        ;;
esac