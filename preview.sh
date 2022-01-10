#! /usr/bin/env bash

python3 -m http.server 8000 &
python_pid=$!

trap "kill $python_pid" EXIT

cp app/js/main.min.js js/main.min.js
cp app/js/main6.min.js js/main6.min.js
elm make --output js/app.js src/Main.elm
fswatch --one-per-batch src/Main.elm | xargs -n1 -I{} elm make --output js/app.js src/Main.elm
