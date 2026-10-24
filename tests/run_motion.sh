#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/prepare_motion.py
export SMW_ROOT="$PWD"
if [[ "${1:-}" == --one ]]; then
 exec timeout 90 "${FCEUX:-fceux}" --no-config 1 --4buttonexit 0 --sound 0 --pal 0 --newppu 1 --loadlua "$PWD/tests/motion_compare.lua" "$PWD/build/smw-nes-physics-v0.2.nes"
fi
if [[ "${SMW_XVFB_TCP:-0}" == 1 ]]; then
 Xvfb :99 -nolisten unix -nolisten local -listen tcp -screen 0 1024x768x24 -ac > build/xvfb-motion.log 2>&1 &
 xpid=$!;trap 'kill "$xpid" 2>/dev/null || true' EXIT
 export DISPLAY=127.0.0.1:99 QT_X11_NO_MITSHM=1;sleep 1
 bash "$0" --one > build/fceux-motion.log 2>&1
elif [[ -n "${DISPLAY:-}" ]]; then
 bash "$0" --one > build/fceux-motion.log 2>&1
else
 xvfb-run -a bash "$0" --one > build/fceux-motion.log 2>&1
fi
cat build/motion-results.txt
rg -q 'differing_values=0 complete=true' build/motion-results.txt
