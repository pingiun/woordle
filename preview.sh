#! /usr/bin/env bash

if gmake --version >/dev/null; then
    # brew on macOS installs GNU make as gmake
    MAKE=gmake
else
    MAKE=make
fi

pushd app
python3 -m http.server 8000 &
python_pid=$!
popd

trap "kill $python_pid" EXIT

$MAKE export OPTIMIZE=""
fswatch --one-per-batch src/Main.elm | xargs -n1 -I{} $MAKE export OPTIMIZE=""
