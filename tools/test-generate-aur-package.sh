#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
mkdir -p .agent-workspace
work=$(mktemp -d "$PWD/.agent-workspace/aur-test.XXXXXXXX")
trap 'find "$work" -depth -delete' EXIT
mkdir -p "$work/bin"
cat > "$work/bin/docker" <<'DOCKER'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$MC_DOCKER_ARGS_FILE"
printf 'pkgname = modconductor-bin\n'
DOCKER
chmod +x "$work/bin/docker"
archive="$work/modconductor-v0.1.0-linux-x64.tar.gz"
printf 'fixture' > "$archive"
export MC_DOCKER_ARGS_FILE="$work/docker-args"
relative_output="${work#"$PWD/"}"/out
PATH="$work/bin:$PATH" bash tools/generate-aur-package.sh "$archive" "$relative_output" 0.1.0
recipe="$work/out/modconductor-bin.PKGBUILD"
bash -n "$recipe"
# shellcheck disable=SC2016
grep -Fq '${pkgver}' "$recipe"
# shellcheck disable=SC2016
grep -Fq '${srcdir}' "$recipe"
# shellcheck disable=SC2016
grep -Fq '${pkgdir}' "$recipe"
grep -Fq "sha256sums=('$(sha256sum "$archive" | cut -d ' ' -f1)')" "$recipe"
grep -Fq -- "-v $work/out:/recipe" "$work/docker-args"
grep -Fq 'pkgname = modconductor-bin' "$work/out/modconductor-bin.SRCINFO"
