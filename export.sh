#! /usr/bin/env bash

rm -rf app/js/*
gmake build

declare -A filenames

for file in app/js/app*.js app/js/main*.js; do
    checksum=$(b3sum --no-names -- "$file")
    basename=$(basename "$file")
    if [[ "$checksum" != "*$basename*" ]]; then
        mv "$file" "app/js/${checksum}-${basename}"
        filenames["$basename"]="${checksum}-${basename}"
    fi
done

cd html
for html in *.html **/*.html; do
    mkdir -p "../app/$(dirname $html)"
    cp "$html" "../app/$html"
    for basename in "${!filenames[@]}"; do
        sed -i '' "s;${basename};${filenames[$basename]};" "../app/$html"
    done
done
