#!/usr/bin/env bash

help() {
  cat <<EOF
  Generates zls sources.json
  Usage
    ./create-sources.sh GITHUB_TOKEN [ARGUMENT]
  Arguments
    -f  Overrides existing sources file
    -o  Output file, defaults to sources.json
    -h  Prints this help
EOF
}

out="sources.json"
OPTIND=2
while getopts :hfo: flag; do
  case "${flag}" in
  o) out="$OPTARG" ;;
  f) force="true" ;;
  *) help && exit 0 ;;
  esac
done

[ -z "$1" ] && printf "Please provide your github token" && exit 1
[ -e "$out" ] && [ -z "$force" ] && printf "Use -f to override %s" "$out" && exit 1

dir="$(mktemp -d)"
cleanup() { rm -rf "${dir:?}"/*; }
trap cleanup EXIT

printf "[\n" >"$out"

i="2"
printf '#'
while read -r item; do
  ver="${item%|*}"
  for elem in ${item#*|}; do
    i=$((i + 1))
    printf "\r"
    printf "#%.0s" $(seq 1 "$i")
    name="${elem#*,}"
    arch="${name%%.*}"
    arch="${arch/zls-/}"
    arch="${arch/macos/darwin}"
    arch="${arch/x64-/i686-}"
    url="${elem%,*}"
    file="$dir/$ver-$name"
    curl -sLo "$file" "$url"
    sha="$(sha256sum "$file" | cut -d' ' -f1)"
    printf '{"url":"%s","version":"%s","sha256":"%s","system":"%s"},\n' "$url" "$ver" "$sha" "$arch" >>"$out"
  done
done < <(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $1" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/zigtools/zls/releases |
  jq 'map("\(.tag_name)|\(.assets | map(
  select(.name | 
    test("^(zls-)?((((x86_|riscv|(long)?aarch)64)|i686|armv7a|s390x|powerpc64le)-(linux|macos|windows)).*z(ip)?$") and 
      (. | test("minisig$") | not)) | 
    "\(.browser_download_url),\(.name)") 
  | join(" "))") | .[]' -r)

truncate -s -2 "$out"
printf "\n]" >>"$out"
