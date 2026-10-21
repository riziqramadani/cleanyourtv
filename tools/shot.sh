#!/usr/bin/env bash
# Pull a screenshot from the TV, working around MediaTek screencap writing junk to stdout.
# Saves to the TV first, then pulls the file. Usage: TV_HOST=... tools/shot.sh <local.png>
set -euo pipefail
: "${TV_HOST:?set TV_HOST}"
OUT="${1:?usage: shot.sh <local.png>}"
cd "$(dirname "$0")/.."
PY=tools/venv/bin/python
[ -x "$PY" ] || PY=tools/venv/Scripts/python.exe
# Press Home-free capture: just grab whatever is on screen to a file on the TV, then pull it.
"$PY" -I tools/tv.py "screencap -p /data/local/tmp/shot.png" >/dev/null
"$PY" -I tools/tv.py --pull /data/local/tmp/shot.png "$OUT" >/dev/null
"$PY" -I tools/tv.py "rm -f /data/local/tmp/shot.png" >/dev/null
SZ=$(wc -c < "$OUT" | tr -d ' ')
echo "saved $OUT ($SZ bytes)"
