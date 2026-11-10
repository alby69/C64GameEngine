#!/usr/bin/env bash
# Convenience wrapper -> scripts/stop.sh
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/stop.sh" "$@"
