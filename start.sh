#!/usr/bin/env bash
# Convenience wrapper -> scripts/start.sh
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts/start.sh" "$@"
