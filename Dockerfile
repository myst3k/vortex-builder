# Optimized Rust builder image with fast compilation tools
FROM lukemathwalker/cargo-chef:latest-rust-1

WORKDIR /app

# Build argument for mold version (can be overridden)
ARG MOLD_VERSION=2.40.4

# Install build tools including mold linker (x86_64), clang, and sccache
RUN apt-get update && apt-get install -y \
    curl \
    clang \
    && curl -L https://github.com/rui314/mold/releases/download/v${MOLD_VERSION}/mold-${MOLD_VERSION}-x86_64-linux.tar.gz | tar -xz -C /usr/local --strip-components=1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install sccache for compilation caching
RUN cargo install sccache --version 0.10.0

# Configure build tools - optimization choices left to user
ENV RUSTC_WRAPPER=sccache
ENV SCCACHE_DIR=/sccache
ENV CC=clang
ENV RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=/usr/local/bin/mold"

# Pre-warm cargo with commonly used crates (optional but helpful)
RUN cargo install cargo-chef && rm -rf /usr/local/cargo/registry/cache

# Label for tracking
LABEL maintainer="rust-builder"
LABEL version="1.0.0"
LABEL description="Pre-built Rust builder with mold, clang, sccache for fast builds"