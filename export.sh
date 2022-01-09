#! /usr/bin/env bash

set -eo pipefail

if [ $# -ne 1 ]; then
    optimize=--optimize
fi

elm make $optimize --output app.js src/Main.elm
mkdir -p app/js
sed 's/app.js/app.min.js/' index.html > app/index.html

$(npm bin)/uglifyjs app.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | $(npm bin)/uglifyjs --mangle --output app/js/app.min.js
(echo -n "const puzzle_words = "; jq --raw-input < data/puzzle-words | jq -s; echo ";"; echo "const all_words = "; jq --raw-input < data/all-words | jq -s; echo ";"; cat js/main.js) | $(npm bin)/uglifyjs --mangle --output app/js/main.min.js
rm app.js
