#! /usr/bin/env bash

set -eo pipefail

if [ $# -ne 1 ]; then
    optimize=--optimize
fi

mkdir -p app/js app/woordle6 app/wordle6 src-en

elm make $optimize --output app.js src/Main.elm

sed 's/{- English -}/English {-/' src/Main.elm > src-en/Main.elm
elm make $optimize --output app-en.js src-en/Main.elm

sed 's/app.js/app.min.js/' index.html > app/index.html
sed 's/app.js/app.min.js/' index6.html > app/woordle6/index.html
sed 's/app.js/app-en.min.js/' wordle6.html > app/wordle6/index.html

$(npm bin)/uglifyjs app.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | $(npm bin)/uglifyjs --mangle --output app/js/app.min.js
$(npm bin)/uglifyjs app-en.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | $(npm bin)/uglifyjs --mangle --output app/js/app-en.min.js
(echo -n "const puzzle_words = "; jq --raw-input < data/puzzle-words | jq -s; echo ";"; echo "const all_words = "; jq --raw-input < data/all-words | jq -s; echo ";"; cat js/main.js) | $(npm bin)/uglifyjs --mangle --output app/js/main.min.js
(echo -n "const puzzle_words = "; jq --raw-input < data/puzzle-words6 | jq -s; echo ";"; echo "const all_words = "; jq --raw-input < data/all-words6 | jq -s; echo ";"; cat js/main6.js) | $(npm bin)/uglifyjs --mangle --output app/js/main6.min.js
(echo -n "const puzzle_words = "; jq --raw-input < data/puzzle-words6 | jq -s; echo ";"; echo "const all_words = "; jq --raw-input < data/all-words6 | jq -s; echo ";"; cat js/main6-en.js) | $(npm bin)/uglifyjs --mangle --output app/js/main6-en.min.js
rm app.js app-en.js
