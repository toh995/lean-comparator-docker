# Compile landrun
FROM golang:1.27-trixie AS landrun-builder
RUN CGO_ENABLED=0 go install github.com/zouuup/landrun/cmd/landrun@main \
    && landrun --version

# Install/compile lean, elan, lean4export, and comparator
FROM debian:trixie-slim AS lean-builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates=20250419 \
        curl=8.14.1-2+deb13u5 \
        git=1:2.47.3-0+deb13u1 \
    && rm -rf /var/lib/apt/lists/*

# Install Elan + Lean
# renovate: datasource=github-tags depName=leanprover/lean4
ARG LEAN_VERSION=v4.34.1
ARG LEAN_TOOLCHAIN=leanprover/lean4:$LEAN_VERSION
ENV ELAN_HOME=/opt/elan
ENV PATH="$ELAN_HOME/bin:$PATH"
RUN curl https://elan.lean-lang.org/elan-init.sh -sSf \
    | sh -s -- -y --no-modify-path --default-toolchain "$LEAN_TOOLCHAIN" \
    && lean --version

# Compile lean4export
# renovate: datasource=github-tags depName=leanprover/lean4export
ARG LEAN4EXPORT_VERSION=v4.34.0
RUN git clone --depth 1 --branch "$LEAN4EXPORT_VERSION" \
    https://github.com/leanprover/lean4export /tmp/lean4export \
    && lake "+$LEAN_TOOLCHAIN" -d /tmp/lean4export build lean4export

# Compile comparator
# renovate: datasource=github-tags depName=leanprover/comparator
ARG COMPARATOR_VERSION=v4.34.0
RUN git clone --depth 1 --branch "$COMPARATOR_VERSION" \
    https://github.com/leanprover/comparator /tmp/comparator \
    && lake "+$LEAN_TOOLCHAIN" -d /tmp/comparator build comparator

# Build the final image
FROM debian:trixie-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# git: required comparator dependency
# python3-seccomp: block-unix-sockets uses it to install its seccomp filter
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        git=1:2.47.3-0+deb13u1 \
        python3-seccomp=2.6.0-2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=landrun-builder /go/bin/landrun /usr/local/bin/landrun

# Lean, as installed by elan. `lean` and `lake` in $ELAN_HOME/bin are only
# launchers: at runtime they read $ELAN_HOME to find the real Lean toolchain.
ENV ELAN_HOME=/opt/elan
COPY --from=lean-builder $ELAN_HOME $ELAN_HOME
COPY --from=lean-builder $ELAN_HOME/bin/ /usr/local/bin/

COPY --from=lean-builder /tmp/lean4export/.lake/build/bin/lean4export /usr/local/bin/lean4export
COPY --from=lean-builder /tmp/comparator/.lake/build/bin/comparator /usr/local/bin/comparator

COPY block-unix-sockets /usr/local/bin/block-unix-sockets

# Comparator requires running unprivileged
RUN useradd --create-home --uid 1000 nonroot
USER nonroot
