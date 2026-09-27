#!/usr/bin/env bash
# Runs a Flutter app's macOS integration tests, then closes the test app.
#
#   tool/macos_integration_test.sh <app dir> [test path ...]
#   tool/macos_integration_test.sh packages/championforms_clipboard/example
#   tool/macos_integration_test.sh packages/championforms_clipboard/example \
#       integration_test/ffi_clipboard_test.dart
#
# `flutter test -d macos` (Flutter 3.47) intermittently leaves the test app's
# window open after reporting results, even for a trivial test. This wrapper
# kills only processes whose executable lives under <app dir>/build/macos/, so
# it can never touch anything else, and exits with flutter's own status.
set -uo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <app dir> [test path ...]" >&2
  exit 64
fi

app_dir="$(cd "$1" && pwd)"
shift
tests=("$@")
[[ ${#tests[@]} -eq 0 ]] && tests=(integration_test)

(cd "$app_dir" && flutter test "${tests[@]}" -d macos)
status=$?

build_dir="$app_dir/build/macos/"
# Give a normal shutdown a moment before forcing it.
for _ in 1 2 3 4 5; do
  pgrep -f "^$build_dir" >/dev/null || break
  sleep 1
done
if pgrep -f "^$build_dir" >/dev/null; then
  echo "Closing leftover test app under $build_dir" >&2
  pkill -f "^$build_dir"
fi

exit "$status"
