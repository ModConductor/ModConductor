FROM ubuntu:24.04

LABEL org.modconductor.tool="reusable-linux-x64-package-builder"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git python3 clang cmake ninja-build pkg-config \
    libgtk-3-dev libepoxy-dev libx11-dev libsecret-1-dev liblzma-dev \
    zlib1g-dev libssl-dev libstdc++-12-dev libunwind-dev libicu-dev \
    fontconfig fonts-dejavu-core libglib2.0-bin xdg-utils xvfb xauth \
    dbus-x11 file binutils \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /root/dotnet-install.sh \
 && bash /root/dotnet-install.sh --version 10.0.400 --install-dir /opt/dotnet \
 && rm /root/dotnet-install.sh

RUN curl -fsSL https://sh.rustup.rs -o /root/rustup-init.sh \
 && RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo \
    sh /root/rustup-init.sh -y --profile minimal --default-toolchain 1.89.0 \
 && rm /root/rustup-init.sh

ENV PATH=/opt/dotnet:/opt/cargo/bin:/src/.tools/flutter/bin:$PATH \
    RUSTUP_HOME=/opt/rustup DOTNET_ROOT=/opt/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 \
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    FLUTTER_SUPPRESS_ANALYTICS=1 DART_SUPPRESS_ANALYTICS=1

WORKDIR /src
