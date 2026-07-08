#!/bin/bash
# Renames artist/album directories whose names contain characters invalid
# on Windows/NTFS and exFAT (< > : " \ | ? *) — such names block syncing
# the whole directory to the exFAT SAILBOAT drive. Uses the same
# substitution convention as the file-renaming scripts: "/" can't occur
# in a directory name, everything else invalid becomes "_".
#
# Renames depth-first (deepest dirs first) so a parent rename never
# invalidates a child's recorded path mid-run. Refuses to overwrite an
# existing directory of the target name.
#
# Note for scan_state.sh users: a renamed album directory gets a new
# relpath, so it shows up as a "new" album on the next scan and any old
# relpath rows in the state file become harmless orphans.
#
# Usage:
#   sanitize_dirnames.sh <library-root>            # rename offending dirs
#   sanitize_dirnames.sh <library-root> --dry-run  # only show what would change
set -uo pipefail
root="${1:?Usage: sanitize_dirnames.sh <library-root> [--dry-run]}"
dry=""
[[ "${2:-}" == "--dry-run" || "${2:-}" == "-n" ]] && dry=1

cd "$root" || exit 1

changed=0
while IFS= read -r d; do
  base=$(basename "$d")
  parent=$(dirname "$d")
  newbase="${base//[\"\<\>:\\|?*]/_}"
  [ "$newbase" = "$base" ] && continue
  target="$parent/$newbase"
  if [ -e "$target" ]; then
    echo "REFUSING to rename '$d' -> '$target' (target already exists)" >&2
    continue
  fi
  if [ -n "$dry" ]; then
    echo "would rename: $d -> $target"
  else
    mv -n -- "$d" "$target"
    echo "renamed: $d -> $target"
  fi
  changed=$((changed + 1))
done < <(/usr/bin/find . -mindepth 1 -depth -type d | sort -r)

[ "$changed" -eq 0 ] && echo "No directory names needed changes."
