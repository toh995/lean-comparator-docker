image_name := "lean-comparator-docker"

# Build the image, then check that comparator accepts the real proof in test/fixture/.
# 1. Mount test/fixture/ read-only at /src, so the test never writes into the host repo.
# 2. Copy it to ~/project, because comparator writes `.lake/` and /src is read-only.
test:
    docker build -t {{image_name}} .
    docker run --rm --network none -v "$PWD/test/fixture:/src:ro" {{image_name}} \
      bash -c 'cp -r /src ~/project && cd ~/project && block-unix-sockets lake env comparator config.json'
