#!/bin/bash
# Splits combined "N/total" TRACKNUMBER and DISCNUMBER tags (a format some
# rippers/streaming exports use) into separate TRACKNUMBER+TRACKTOTAL and
# DISCNUMBER+DISCTOTAL tags, zero-padding TRACKNUMBER to 2 digits. Also
# zero-pads a plain (non-combined) TRACKNUMBER that's stored unpadded
# (e.g. "1" instead of "01") — this happens on rips where a rename-only
# fix corrected the filename but never touched the tag itself. Unpadded
# TRACKNUMBER sorts lexicographically wrong (1, 10, 11, ..., 2, 3, ...) in
# some players even though the filename looks fine. Leaves already-plain
# 2-digit tags untouched.
#
# Usage: fix_tracknumber_format.sh <album-dir>
set -uo pipefail
dir="${1:?Usage: fix_tracknumber_format.sh <album-dir>}"
cd "$dir" || exit 1

for f in *.flac; do
  tn=$(metaflac --show-tag=TRACKNUMBER "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
  dn=$(metaflac --show-tag=DISCNUMBER "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
  changed=0

  if [[ "$tn" =~ ^([0-9]+)/([0-9]+)$ ]]; then
    n="${BASH_REMATCH[1]}"
    tot="${BASH_REMATCH[2]}"
    metaflac --remove-tag=TRACKNUMBER --remove-tag=TRACKTOTAL \
      --set-tag="TRACKNUMBER=$(printf '%02d' "$((10#$n))")" \
      --set-tag="TRACKTOTAL=$tot" "$f"
    changed=1
  elif [[ "$tn" =~ ^[0-9]+$ ]] && [ ${#tn} -lt 2 ]; then
    metaflac --remove-tag=TRACKNUMBER \
      --set-tag="TRACKNUMBER=$(printf '%02d' "$((10#$tn))")" "$f"
    changed=1
  fi

  if [[ "$dn" =~ ^([0-9]+)/([0-9]+)$ ]]; then
    d="${BASH_REMATCH[1]}"
    dtot="${BASH_REMATCH[2]}"
    metaflac --remove-tag=DISCNUMBER --remove-tag=DISCTOTAL \
      --set-tag="DISCNUMBER=$d" \
      --set-tag="DISCTOTAL=$dtot" "$f"
    changed=1
  fi

  [ "$changed" -eq 1 ] && echo "Normalized track/disc numbering: $f (was track=$tn disc=$dn)"
done
