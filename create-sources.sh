#!/usr/bin/env bash

help() {
  cat << EOF 
  Generates zls sources.json
  Usage
    ./create-sources.sh GITHUB_TOKEN [ARGUMENT]
  Arguments
    -f  Overrides existing sources.json
    -h  Prints this help
EOF
}

OPTIND=2
while getopts :hf flag
do
    case "${flag}" in
        f) force="true"   ;;
        *) help && exit 0 ;;
    esac
done

[ -z "$1" ] && printf "Please provide your github token" && exit 1
[ -e sources.json ] && [ -z "$force" ] && printf "Use -f to override sources.json" && exit 1

dir="$(mktemp -d)"
cleanup() { rm -rf "${dir:?}"/*; }
trap cleanup EXIT

printf "[\n" > sources.json

i="2"
printf '#'
while read -r item; do 
  ver="${item%|*}"
  for elem in ${item#*|}; do 
    i=$((i+1))
    printf "\r"
    printf "#%.0s" $(seq 1 "$i")
    name="${elem#*,}"
    arch="${name%%.*}"
    arch="${arch/zls-/}"
    arch="${arch/macos/darwin}"
    url="${elem%,*}"
    file="$dir/$ver-$name"
    curl -sLo "$file" "$url"
    sha="$(sha256sum "$file" | cut -d' ' -f1)"
    printf '{"url": "%s", "version": "%s", "sha256": "%s", "arch": "%s" }, \n' "$url" "$ver" "$sha" "$arch" >> sources.json
  done
done < <(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $1" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/zigtools/zls/releases | 
  jq '
map("\(.tag_name)|\(.assets | map(select(.name | test("^zls-(aarch64-(linux|macos)|x86_64-linux)") and (. | test("minisig$") | not)) | "\(.browser_download_url),\(.name)") | join(" "))") | .[]
' -r)

truncate -s -3 sources.json 
printf "\n]" >> sources.json
