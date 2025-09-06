# Vortex Builder

Pre-built Docker base image with optimized Rust build tools for fast compilation.

## Platform Support

**x86_64/amd64 only** - This image is built specifically for Intel/AMD 64-bit processors.

ARM/Apple Silicon users should build locally or adapt the Dockerfile for their platform.

## Features

- **cargo-chef** for Docker layer caching
- **mold** linker for faster linking (auto-updates to latest)
- **clang** compiler for mold support
- **sccache** for compilation caching
- Pre-configured for fast parallel builds

## Usage

This image is automatically built and published to GitHub Container Registry.

### In your Dockerfile:

```dockerfile
FROM ghcr.io/myst3k/vortex-builder:latest AS chef
WORKDIR /app

# Your build steps here...
```

### Pull the image:

```bash
docker pull ghcr.io/myst3k/vortex-builder:latest
```

## Automated Builds

This image is automatically rebuilt when:
- The base image (cargo-chef) updates
- A new version of mold is released
- Changes are made to the Dockerfile
- Manually triggered via GitHub Actions

Daily checks ensure we stay up-to-date with the latest stable releases.

## Tags

- `latest` - Latest stable build
- `YYYYMMDD` - Date-tagged builds
- `main-<sha>` - Commit-specific builds

## Build Locally

```bash
docker build -t vortex-builder:latest .
```

## Pre-configured Tools

The image includes:
- `RUSTC_WRAPPER=sccache` - Compilation caching enabled
- `CC=clang` - Clang compiler for mold support
- `RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=/usr/local/bin/mold"` - Mold linker configured

## Configuration Examples

### Complete Dockerfile Example
```dockerfile
FROM ghcr.io/myst3k/vortex-builder:latest AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json

# Build dependencies - this layer is cached
RUN --mount=type=cache,target=/sccache,sharing=locked \
    --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    cargo chef cook --release --recipe-path recipe.json

# Copy source code and build application
COPY . .
RUN --mount=type=cache,target=/sccache,sharing=locked \
    --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    cargo build --release

# Runtime stage
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    curl \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/your-app /usr/local/bin/your-app
ENTRYPOINT ["/usr/local/bin/your-app"]
```

### Configure via .cargo/config.toml
For project-wide settings, use `.cargo/config.toml` in your repository:

```toml
# For fast development builds
[profile.release]
lto = false
codegen-units = 16
opt-level = 2

# For production builds
[profile.production]
inherits = "release"
lto = "fat"
codegen-units = 1
opt-level = 3
strip = true
```

Then build with: `cargo build --profile production`

