#!/bin/bash
# Run through Orb from the workspace checkout; source and build files stay here.
set -euo pipefail
[ "$(uname -s)" = Linux ] || { echo 'Use orb -m trixie.' >&2; exit 1; }
source_tree=$(cd "$(dirname "$0")/../.." && pwd)
cd "$source_tree"
mkdir -p tmp logs
if [ ! -f tmp/config.original ]; then
    cp "$source_tree/.config" tmp/config.original
    cp tmp/config.original .config
fi
python3 ./scripts/llvm/force-llvm-config.py .config
./scripts/llvm/enter.sh defconfig > logs/llvm-defconfig.log 2>&1
./scripts/llvm/enter.sh "$@"
