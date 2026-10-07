#!/usr/bin/env python3
"""Keep the active OpenWrt configuration on the host LLVM toolchain."""

import sys
from pathlib import Path


if len(sys.argv) != 2:
    raise SystemExit(f"usage: {sys.argv[0]} CONFIG_FILE")

config = Path(sys.argv[1])
if not config.is_file() or config.is_symlink():
    raise SystemExit(f"refusing to update a missing or linked config: {config}")

settings = {
    "USE_LLVM_TOOLCHAIN": "y",
    "BPF_TOOLCHAIN_HOST": "y",
}
discard = {
    "USE_LLVM_BUILD",
    "USE_LLVM_PREBUILT",
    "BPF_TOOLCHAIN_BUILD_LLVM",
    "BPF_TOOLCHAIN_PREBUILT",
    "BPF_TOOLCHAIN_NONE",
    *settings,
}

lines = config.read_text().splitlines()
lines = [
    line
    for line in lines
    if not any(
        line.startswith(f"CONFIG_{key}=") or line == f"# CONFIG_{key} is not set"
        for key in discard
    )
]
lines.extend(f"CONFIG_{key}={value}" for key, value in settings.items())
config.write_text("\n".join(lines) + "\n")
