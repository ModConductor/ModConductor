#!/usr/bin/env bash
set -euo pipefail
appdir=$1
documentation="$appdir/usr/lib/modconductor/share/doc/modconductor/third-party/ubuntu-24.04"
mkdir -p "$documentation"
listing="$documentation/bundled-ubuntu-packages.tsv"
printf 'package\tversion\tsource_package\tsource_version\tappdir_path\tubuntu_path\n' > "$listing"
declare -A packages=()
for resource in gsettings-desktop-schemas libglib2.0-bin libgtk-3-0t64 fontconfig fonts-dejavu-core xdg-utils libsecret-1-0 adwaita-icon-theme shared-mime-info; do
  packages["$resource"]=1
done
while IFS= read -r -d '' file; do
  relative=${file#"$appdir/usr/lib/"}
  [[ $relative != modconductor/* ]] || continue
  source=/usr/lib/"$relative"
  [[ -e $source ]] || source=/lib/"$relative"
  [[ -e $source ]] || continue
  package=$(dpkg-query -S "$source" 2>/dev/null | head -1 | sed 's/: .*//') || :
  [[ -n $package ]] || continue
  packages["$package"]=1
  printf '%s\t%s\n' "$package" "$relative" >> "$documentation/bundled-files.tsv"
done < <(find "$appdir/usr/lib" -type f -print0)
while IFS= read -r package; do
  version=$(dpkg-query -W -f='${Version}' "$package")
  source_package=$(dpkg-query -W -f='${source:Package}' "$package")
  source_version=$(dpkg-query -W -f='${source:Version}' "$package")
  source_package=${source_package:-${package%%:*}}
  source_version=${source_version:-$version}
  copyright="/usr/share/doc/${package%%:*}/copyright"
  [[ -f $copyright ]] || { echo "Missing copyright for $package" >&2; exit 1; }
  cp "$copyright" "$documentation/${package//:/-}.copyright"
  found_any=false
  if [[ -f $documentation/bundled-files.tsv ]]; then
    while IFS=$'\t' read -r found path; do
      [[ $found == "$package" ]] || continue
      found_any=true
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$package" "$version" "$source_package" "$source_version" "usr/lib/$path" "/usr/lib/$path" >> "$listing"
    done < "$documentation/bundled-files.tsv"
  fi
  $found_any || printf '%s\t%s\t%s\t%s\t.\tresource\n' "$package" "$version" "$source_package" "$source_version" >> "$listing"
done < <(printf '%s\n' "${!packages[@]}" | sort)
rm -f "$documentation/bundled-files.tsv"
