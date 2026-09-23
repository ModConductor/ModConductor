FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    binutils ca-certificates dpkg-dev file findutils fontconfig fonts-dejavu-core \
    gsettings-desktop-schemas libegl1 libepoxy0 libgles2 libgtk-3-bin libgtk-3-dev \
    libgirepository1.0-dev libglib2.0-bin libicu74 liblzma5 libsecret-1-dev \
    librsvg2-dev libssl3t64 libunwind8 patchelf pkg-config python3 \
    xdg-utils zlib1g \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
