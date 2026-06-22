#!/usr/bin/env bash
# Build machin-batch: mint canonical .mfl, then compile to a native binary.
# Point at a local machin build with MACHIN=/path/to/machin ./build.sh
set -euo pipefail
MACHIN="${MACHIN:-machin}"
"$MACHIN" encode batch.src > batch.mfl
"$MACHIN" build batch.mfl -o machin-batch
echo "built ./machin-batch"
