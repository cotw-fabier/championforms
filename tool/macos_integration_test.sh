#!/usr/bin/env bash
# Runs a Flutter app's macOS integration tests, then closes the test app.
#
#   tool/macos_integration_test.sh <app dir> [test path ...]
#   tool/macos_integration_test.sh packages/championforms_clipboard/example
#   tool/macos_integration_test.sh packages/championforms_clipboard/example \
#       integration_test/ffi_clipboard_test.dart
#
# With `flutter test -d macos` (Flutter 3.47, macOS 26), flutter terminates
# the test app after reporting, but macOS intermittently relaunches it about
# 0.3 s later: a new process, parented by launchd, with no arguments. It is
# reproducible in a freshly created app with no plugins or native assets, so
# it is not caused by this repo's code. This wrapper kills only processes
# whose executable lives under <app dir>/build/macos/, so it can never touch
# anything else, and exits with flutter's own status.
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
sleep 1  # let a delayed relaunch appear before checking
for _ in 1 2 3 4 5; do
  pgrep -f "^$build_dir" >/dev/null || break
  sleep 1
done
if pgrep -f "^$build_dir" >/dev/null; then
  echo "Closing leftover test app under $build_dir" >&2
  pkill -f "^$build_dir"
fi

exit "$status"
