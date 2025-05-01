# Dockerfile for building SFZ module for Move Anything (ARM64)
# Uses Debian bullseye for GCC 10 / GLIBCXX_3.4.29 compatibility with Move device
FROM debian:bullseye-slim

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
