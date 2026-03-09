# Dockerfile for building SFZ module for Move Anything (ARM64)
# Includes CMake for building sfizz from source
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    cmake \
    git \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

ENV CROSS_PREFIX=aarch64-linux-gnu-

WORKDIR /build
