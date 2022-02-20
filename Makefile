# This needs GNU compatible make
.ONESHELL:

NPMBIN := $(shell npm bin)
OPTIMIZE ?= --optimize
SHELL = bash

app/js/app-be.min.js: src/Main.elm
	mkdir src-be
	sed 's/{- Flemish -}/Flemish {-/' src/Main.elm > src-be/Main.elm
	elm make $(OPTIMIZE) --output app-be.js src-be/Main.elm
	if [[ -n "$(OPTIMIZE)" ]]; then
		$(NPMBIN)/uglifyjs app-be.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | $(NPMBIN)/uglifyjs --mangle --output app/js/app-be.min.js
	else
		cp app-be.js app/js/app-be.min.js
	fi
	rm -rf app-be.js

app/js/app.min.js: src/Main.elm
	elm make $(OPTIMIZE) --output app.js src/Main.elm
	if [[ -n "$(OPTIMIZE)" ]]; then
		$(NPMBIN)/uglifyjs app.js --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | $(NPMBIN)/uglifyjs --mangle --output app/js/app.min.js
	else
		cp app.js app/js/app.min.js
	fi
	rm -rf app.js

app/js/main.min.js: js/main.js
	(echo -n "const puzzle_words = "; jq --raw-input < data/puzzle-words | jq -s; echo ";"; echo "const all_words = "; jq --raw-input < data/all-words | jq -s; echo ";"; cat js/main.js) | $(NPMBIN)/uglifyjs --mangle --output app/js/main.min.js

app/js/main-be.min.js: js/main-be.js
	(echo -n "const puzzle_words = "; jq --raw-input < data/puzzle-words-be | jq -s; echo ";"; echo "const all_words = "; jq --raw-input < data/all-words-be | jq -s; echo ";"; cat js/main-be.js) | $(NPMBIN)/uglifyjs --mangle --output app/js/main-be.min.js

build: app/js/app.min.js app/js/main.min.js app/js/app-be.min.js app/js/main-be.min.js

.PHONY: build export
