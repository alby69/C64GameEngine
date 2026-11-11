#!/usr/bin/env bash
# C64GameEngine - start the docker stack
# Auto-detects OS and runs the appropriate stack (Linux/macOS or Windows)
set -euo pipefail

# Determine script directory and project root
# BASH_SOURCE[0] is this script's path (e.g., ./start.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Project root is the directory containing this script (since it's at the root)
PROJECT_ROOT="${SCRIPT_DIR}"

# Detect operating system
OS="$(uname -s)"
case "${OS}" in
    Linux*|Darwin*)
        # Linux or macOS - use the Linux bin script
        exec "${PROJECT_ROOT}/bin/linux/start.sh" "$@"
        ;;
    Windows*)
        # Windows - use the Windows bin script
        exec "%~dp0bin/windows/start.bat" "$@"
        ;;
    *)
        err "Sistema operativo non supportato: ${OS}"
        exit 1
        ;;
esac