# This needs GNU compatible make
.ONESHELL:

NPMBIN := $(shell npm bin)
OPTIMIZE ?= --optimize
SHELL = bash

app/js/app.min.js: src/Main.elm
	elm make $(OPTIMIZE) --output app.js src/Main.elm
	if [[ -n "$(OPTIMIZE)" ]]; then
		$(NPMBIN)/uglifyjs app.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | $(NPMBIN)/uglifyjs --mangle --output app/js/app.min.js
	else
		cp app.js app/js/app.min.js
	fi
	rm -rf app.js

app/js/main.min.js: js/main.js
	(echo -n "const puzzle_words = "; jq --raw-input < data/all-words-fy | jq -s; echo ";"; echo "const all_words = "; jq --raw-input < data/all-words-fy | jq -s; echo ";"; cat js/main.js) | $(NPMBIN)/uglifyjs --mangle --output app/js/main.min.js

app/js/main6.min.js: js/main6.js
	(echo -n "const puzzle_words = "; jq --raw-input < data/all-words6-fy | jq -s; echo ";"; echo "const all_words = "; jq --raw-input < data/all-words6-fy | jq -s; echo ";"; cat js/main6.js) | $(NPMBIN)/uglifyjs --mangle --output app/js/main6.min.js

build: app/js/app-en.min.js app/js/app.min.js app/js/main.min.js app/js/main6.min.js

export: build
	./export.sh

.PHONY: build export
