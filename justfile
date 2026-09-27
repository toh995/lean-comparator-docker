export image_name := "lean-comparator-docker"

# Build the image, then test it
test:
    docker build -t {{image_name}} .
    docker compose -f test/compose.yaml run --rm test
