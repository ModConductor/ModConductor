#!/usr/bin/env bash
set -euo pipefail
rid='' publish_directory='' version='' revision=''
while (($#)); do
  case "$1" in
    --rid) rid=$2 ;;
    --publish-directory) publish_directory=$2 ;;
    --version) version=$2 ;;
    --revision) revision=$2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift 2
done
[[ $rid == linux-x64 && -n $publish_directory && -n $version && -n $revision ]] || { echo "Expected native Linux x64 package arguments" >&2; exit 2; }
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
[[ ! -e $publish_directory ]] || { echo "Package output must be a new directory" >&2; exit 1; }
[[ $(dotnet --version) == 10.0.400 ]] || { echo ".NET SDK 10.0.400 required" >&2; exit 1; }
if [[ ! -x .tools/flutter/bin/flutter ]]; then
  mkdir -p .tools
  archive=$(mktemp .tools/flutter.XXXXXXXX.tar.xz)
  trap 'rm -f "$archive"' EXIT
  curl -fL "$(jq -r .linux.url .config/flutter-sdk.json)" -o "$archive"
  echo "$(jq -r .linux.sha256 .config/flutter-sdk.json)  $archive" | sha256sum --check
  tar -xf "$archive" -C .tools
  rm "$archive"
  trap - EXIT
fi
[[ $(git rev-parse HEAD) == "$revision" ]] || { echo "Source revision mismatch" >&2; exit 1; }
docker build -t modconductor-linux-package:local -f tools/linux-package/Dockerfile tools/linux-package
mkdir -p .agent-workspace
work=$(mktemp -d "$root/.agent-workspace/package-linux.XXXXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/home"
docker run --rm --init --user "$(id -u):$(id -g)" -v "$root:/src" -w /src \
  -e HOME="/src/${work#"$root/"}"/home \
  -e DOTNET_CLI_HOME="/src/${work#"$root/"}"/home \
  -e NUGET_PACKAGES=/src/.tools/dotnet-cli/.nuget/packages \
  -e PUB_CACHE=/src/.tools/pub-cache \
  -e CARGO_HOME="/src/${work#"$root/"}"/cargo-home \
  -e PATH=/src/.tools/flutter/bin:/opt/dotnet:/opt/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  modconductor-linux-package:local bash tools/package-linux.sh \
    --publish-directory "/src/$publish_directory" --version "$version" --revision "$revision" \
    --work-directory "/src/${work#"$root/"}"/build
