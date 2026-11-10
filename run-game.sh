#!/usr/bin/env bash
# Wrapper comodo dal root del progetto -> scripts/run-game.sh
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/run-game.sh" "$@"
