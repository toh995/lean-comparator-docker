#!/usr/bin/env bash
# Usage: test/run.sh
#
# Builds the image, then checks that comparator accepts the real proof in
# test/fixture/.
set -euo pipefail

cd "$(dirname "$0")/.."

docker build -t lean-comparator-docker .

# 1. Mount test/fixture/ read-only at /src, so the test never writes into the host repo.
# 2. Copy it to ~/project, because comparator writes `.lake/` and /src is read-only.
docker run --rm --network none -v "$PWD/test/fixture:/src:ro" lean-comparator-docker \
  bash -c 'cp -r /src ~/project && cd ~/project && block-unix-sockets lake env comparator config.json'
