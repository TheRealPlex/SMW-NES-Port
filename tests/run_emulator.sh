#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export SMW_ROOT="$PWD"
FCEUX="${FCEUX:-fceux}"
if ! command -v "$FCEUX" >/dev/null; then
  echo 'FCEUX unavailable: emulator tests NOT RUN.' >&2
  exit 77
fi
export FCEUX="$(command -v "$FCEUX")"
if [[ "${1:-}" == --one ]]; then
  exec timeout 90 "$FCEUX" --no-config 1 --sound 0 --pal 0 --newppu 1 --loadlua "$PWD/tests/$2" "$PWD/build/smw-nes-phase1.nes"
fi
mkdir -p build
rm -f build/emulator-results.txt build/persistence-results.txt build/traversal-results.txt
run_suite() {
  bash "$SMW_ROOT/tests/run_emulator.sh" --one "$1"
}
if [[ "${SMW_XVFB_TCP:-0}" == 1 ]]; then
  export DISPLAY=127.0.0.1:99
  export QT_X11_NO_MITSHM=1
  Xvfb :99 -nolisten unix -nolisten local -listen tcp -screen 0 1024x768x24 -ac > build/xvfb.log 2>&1 &
  xpid=$!
  trap 'kill "$xpid" 2>/dev/null || true' EXIT
  sleep 1
  run_suite gameplay.lua > build/fceux.log 2>&1
  run_suite persistence.lua > build/fceux-persistence.log 2>&1
  run_suite traversal.lua > build/fceux-traversal.log 2>&1
elif [[ -n "${DISPLAY:-}" ]]; then
  run_suite gameplay.lua > build/fceux.log 2>&1
  run_suite persistence.lua > build/fceux-persistence.log 2>&1
  run_suite traversal.lua > build/fceux-traversal.log 2>&1
else
  xvfb-run -a bash "$PWD/tests/run_emulator.sh" --one gameplay.lua > build/fceux.log 2>&1
  xvfb-run -a bash "$PWD/tests/run_emulator.sh" --one persistence.lua > build/fceux-persistence.log 2>&1
  xvfb-run -a bash "$PWD/tests/run_emulator.sh" --one traversal.lua > build/fceux-traversal.log 2>&1
fi
python3 tools/convert_captures.py
cat build/emulator-results.txt build/persistence-results.txt build/traversal-results.txt
if ! rg -q '^FAILURES 0$' build/emulator-results.txt; then echo 'Gameplay suite did not finish cleanly'; tail -30 build/fceux.log; exit 1; fi
if rg -q '^FAIL ' build/emulator-results.txt build/persistence-results.txt build/traversal-results.txt; then exit 1; fi
