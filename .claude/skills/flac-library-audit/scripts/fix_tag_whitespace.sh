#!/bin/bash
# Strips leading/trailing whitespace and collapses doubled internal spaces
# in the TITLE, ALBUM, and ARTIST tags of every .flac in an album dir.
# Does not touch filenames — re-run rename_from_tags.sh afterward if you
# also want filenames regenerated from the cleaned-up tags.
#
# Usage: fix_tag_whitespace.sh <album-dir>
set -uo pipefail
dir="${1:?Usage: fix_tag_whitespace.sh <album-dir>}"
cd "$dir" || exit 1

clean() { sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]{2,}/ /g'; }

for f in *.flac; do
  changed=0
  for tag in TITLE ALBUM ARTIST; do
    val=$(metaflac --show-tag="$tag" "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    [ -z "$val" ] && continue
    new_val=$(printf '%s' "$val" | clean)
    if [ "$new_val" != "$val" ]; then
      metaflac --remove-tag="$tag" --set-tag="$tag=$new_val" "$f"
      changed=1
    fi
  done
  [ "$changed" -eq 1 ] && echo "Cleaned whitespace: $f"
done
