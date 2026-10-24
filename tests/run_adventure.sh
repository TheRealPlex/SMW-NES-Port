#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export SMW_ROOT="$PWD"
if [[ "${1:-}" == --one ]]; then
 exec timeout 120 "${FCEUX:-fceux}" --no-config 1 --4buttonexit 0 --sound 0 --pal 0 --newppu 1 --loadlua "$PWD/tests/${2:-adventure.lua}" "$PWD/build/smw-nes-adventure-v0.3.nes"
fi
rm -f build/adventure-results.txt build/persistence-results.txt build/traversal-results.txt
run_all() {
 bash "$0" --one adventure.lua > build/fceux-adventure.log 2>&1
 bash "$0" --one persistence_v03.lua > build/fceux-persistence.log 2>&1
 bash "$0" --one adventure_traversal.lua > build/fceux-traversal.log 2>&1
}
if [[ "${1:-}" == --all ]]; then run_all; exit; fi
if [[ "${SMW_XVFB_TCP:-0}" == 1 ]]; then
 xdisplay=$((100 + RANDOM % 500))
 Xvfb ":$xdisplay" -nolisten unix -nolisten local -listen tcp -screen 0 1024x768x24 -ac > build/xvfb-adventure.log 2>&1 &
 xpid=$!;trap 'kill "$xpid" 2>/dev/null || true' EXIT
 export DISPLAY="127.0.0.1:$xdisplay" QT_X11_NO_MITSHM=1;sleep 1
 bash "$0" --all
elif [[ -n "${DISPLAY:-}" ]]; then bash "$0" --all
else xvfb-run -a bash "$0" --all
fi
cat build/adventure-results.txt build/persistence-results.txt build/traversal-results.txt
rg -q '^FAILURES 0$' build/adventure-results.txt
! rg -q '^FAIL ' build/persistence-results.txt build/traversal-results.txt
