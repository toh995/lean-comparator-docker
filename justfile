export image_name := "lean-comparator-docker"

# Build the image, then test it
test-local: && test-ci
    docker build -t {{image_name}} .

# Test the already-built image (CI builds the image on its own)
test-ci:
    docker compose -f test/compose.yaml run --rm test
