#!/bin/bash
# Renames FLAC files in one album directory into "## - Title.flac" form,
# for the common case where the number and title are already both present
# in the filename but the separator is wrong (e.g. "01. Title.flac",
# "01-Title.flac", "01_Title.flac"). Does NOT touch tags.
#
# Characters invalid on Windows/NTFS and exFAT (< > : " \ | ? *) in the
# title portion are replaced with "_" — they break syncing to the exFAT
# SAILBOAT drive.
#
# Usage: rename_to_standard.sh <album-dir>
set -uo pipefail
dir="${1:?Usage: rename_to_standard.sh <album-dir>}"
cd "$dir" || exit 1

for f in *.flac; do
  if [[ "$f" =~ ^([0-9]+)[.\ _-]+(.+)\.flac$ ]]; then
    n="${BASH_REMATCH[1]}"
    t="${BASH_REMATCH[2]}"
    t="${t//[\"\<\>:\\|?*]/_}"
    new=$(printf "%02d - %s.flac" "$((10#$n))" "$t")
    if [ "$f" != "$new" ]; then
      mv -n -v -- "$f" "$new"
    fi
  else
    echo "NO MATCH (leave alone, inspect manually): $f"
  fi
done
