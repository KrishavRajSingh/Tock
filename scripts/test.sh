#!/bin/bash
# Runs the test suite. With Command Line Tools only (no Xcode), Swift Testing
# is installed but not on the default search path, so add it.
set -euo pipefail
cd "$(dirname "$0")/.."

frameworks=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
if [[ "$(xcode-select -p)" == /Library/Developer/CommandLineTools* && -d "$frameworks/Testing.framework" ]]; then
    exec swift test \
        -Xswiftc -F -Xswiftc "$frameworks" \
        -Xlinker -F -Xlinker "$frameworks" \
        -Xlinker -rpath -Xlinker "$frameworks" \
        "$@"
fi
exec swift test "$@"
