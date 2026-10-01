#!/bin/bash
# Runs the test suite. With Command Line Tools only (no Xcode), Swift Testing
# is installed but not on the default search path, so add it. The Command Line
# Tools also ship the Testing/Foundation overlay without its module, so tests
# that import both need cross-import overlays turned off.
set -euo pipefail
cd "$(dirname "$0")/.."

frameworks=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
if [[ "$(xcode-select -p)" == /Library/Developer/CommandLineTools* && -d "$frameworks/Testing.framework" ]]; then
    exec swift test \
        -Xswiftc -F -Xswiftc "$frameworks" \
        -Xlinker -F -Xlinker "$frameworks" \
        -Xlinker -rpath -Xlinker "$frameworks" \
        -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays \
        "$@"
fi
exec swift test "$@"
