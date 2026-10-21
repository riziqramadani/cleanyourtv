#!/usr/bin/env bash
# Full restore for the CHiQ L43G7P Pro ("Zea TV", Changhong AI PONT / osaka, Google TV 14).
# Captured 2026-10-21 before any debloat. This re-enables EVERY package that this backup
# recorded as enabled at capture time, and puts Home back to the stock launcher.
#
# This is the belt-and-braces restore: it ignores the debloat list and simply re-enables
# everything that was enabled when the backup was taken. For a precise, list-aware undo use
#   TV_HOST=192.168.1.7 tools/restore.sh examples/chiq-l43g7p/debloat.txt com.google.android.apps.tv.launcherx
#
# Usage: TV_HOST=192.168.1.7 backups/chiq-l43g7p-20261021-161630/restore-all.sh
set -euo pipefail
: "${TV_HOST:?set TV_HOST to the TV IP, e.g. TV_HOST=192.168.1.7 $0}"
cd "$(dirname "$0")/../.."
PY=tools/venv/bin/python
[ -x "$PY" ] || PY=tools/venv/Scripts/python.exe
[ -x "$PY" ] || { echo "run: python3 -m venv tools/venv && tools/venv/bin/pip install -r tools/requirements.txt"; exit 1; }
BK="backups/chiq-l43g7p-20261021-161630"
STOCK=com.google.android.apps.tv.launcherx

# Packages that were ENABLED at capture time = everything installed minus everything the
# backup recorded as already-disabled. Re-enable each; one pm command per shell call.
grep '^package:' "$BK/packages-all.txt" | sed 's/^package://' | sort -u > /tmp/.cytv_all.txt
grep '^package:' "$BK/packages-disabled.txt" | sed 's/^package://' | sort -u > /tmp/.cytv_dis.txt
# Enabled-at-capture = all - disabled-at-capture. We re-enable those (re-enabling an already
# enabled package is a no-op, so this is safe even for ones never touched).
comm -23 /tmp/.cytv_all.txt /tmp/.cytv_dis.txt > /tmp/.cytv_enable.txt

echo "Re-enabling $(wc -l < /tmp/.cytv_enable.txt) packages that were enabled at backup time..."
{
  while read -r p; do
    [ -n "$p" ] && echo "pm enable $p"
  done < /tmp/.cytv_enable.txt
  # Put Home back to the stock launcher and clear the custom one's default if present.
  echo "cmd package set-home-activity --user 0 $STOCK/.home.HomeActivity"
  echo "pm list packages -d"
} | "$PY" -I tools/tv.py --batch

rm -f /tmp/.cytv_all.txt /tmp/.cytv_dis.txt /tmp/.cytv_enable.txt
echo
echo "Done. Reboot the TV to be safe:  TV_HOST=$TV_HOST tools/tv.py reboot"
echo "The packages that were already disabled from the factory are left disabled on purpose:"
cat "$BK/packages-disabled.txt" | sed 's/^/  /'
