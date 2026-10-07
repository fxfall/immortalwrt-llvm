#!/bin/bash
# Run through Orb from the workspace checkout. All legacy compiler names resolve to Clang.
set -euo pipefail
source "$(dirname "$0")/setup-env.sh"
exec make "$@"
