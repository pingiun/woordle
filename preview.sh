#! /usr/bin/env bash

pushd app
python3 -m http.server 8000 &
python_pid=$!
popd

trap "kill $python_pid" EXIT


./export.sh dev
fswatch --one-per-batch src/Main.elm | xargs -n1 -I{} ./export.sh dev
