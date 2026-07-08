#!/bin/bash
# Renames every FLAC in one album directory to "## - Title.flac" derived
# directly from that file's own TRACKNUMBER and TITLE tags. Use this when
# the filename itself is unusable (garbage/duplicated/concatenated) but
# the tags are trustworthy — fix the tags first (see SKILL.md), then run
# this to make filenames match.
#
# A literal "/" in the title is replaced with "-" since it can't appear
# in a filename. Characters invalid on Windows/NTFS and exFAT
# (< > : " \ | ? *) are replaced with "_" — they break syncing to the
# exFAT SAILBOAT drive, matching consolidate_multidisc.sh's convention.
#
# Usage: rename_from_tags.sh <album-dir>
set -uo pipefail
dir="${1:?Usage: rename_from_tags.sh <album-dir>}"
cd "$dir" || exit 1

for f in *.flac; do
  n=$(metaflac --show-tag=TRACKNUMBER "$f" | sed -E 's/^[^=]+=//')
  t=$(metaflac --show-tag=TITLE "$f" | sed -E 's/^[^=]+=//')
  t="${t//\//-}"
  t="${t//[\"\<\>:\\|?*]/_}"
  if [ -z "$n" ] || [ -z "$t" ]; then
    echo "SKIP (missing TRACKNUMBER or TITLE tag): $f"
    continue
  fi
  new=$(printf "%02d - %s.flac" "$((10#$n))" "$t")
  if [ "$f" != "$new" ]; then
    mv -n -v -- "$f" "$new"
  fi
done
