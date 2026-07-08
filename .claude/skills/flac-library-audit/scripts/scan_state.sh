#!/bin/bash
# Incremental audit: only scans/reports albums that are new or whose
# .flac contents changed since they were last recorded as clean/accepted.
# This is the script to run every time you add music to an existing
# library, instead of re-running the full audit from scratch.
#
# State lives OUTSIDE the music library, under this skill's own
# state/ directory, keyed by a hash of the library root's absolute path
# — so it never clutters the library and works across multiple libraries.
#
# Usage:
#   scan_state.sh <library-root>
#       Scan only new/changed albums, print issues found (same format as
#       audit.sh), and auto-record any album with zero issues as clean.
#
#   scan_state.sh <library-root> --accept "<album-relpath>"
#       Manually mark an album clean at its CURRENT contents even though
#       it still has flagged issues — use this once you and Claude have
#       reviewed the remaining issues and decided they're an intentional
#       style choice (e.g. simplified filenames) rather than a bug, so it
#       stops resurfacing on every future scan. <album-relpath> is the
#       path exactly as printed after "##ALBUM##" (relative to the root).
#
#   scan_state.sh <library-root> --reset
#       Forget all recorded state for this library root (does not touch
#       any music files) so the next scan is a full fresh scan.
#
#   scan_state.sh <library-root> --list
#       Print what's currently recorded in state for this root.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ROOT_ARG="${1:?Usage: scan_state.sh <library-root> [--accept <album-relpath> | --reset | --list]}"
ROOT="$(cd "$ROOT_ARG" && pwd)"
ACTION="${2:-}"

STATE_DIR="$SCRIPT_DIR/../state"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/$(printf '%s' "$ROOT" | sha1sum | cut -d' ' -f1).tsv"
touch "$STATE_FILE"

get_stored_fp() {
  awk -F'\t' -v p="$1" '$1==p{print $2}' "$STATE_FILE"
}

set_stored() {
  # set_stored <relpath> <fingerprint> <status>
  local tmp
  tmp=$(mktemp)
  awk -F'\t' -v p="$1" '$1!=p' "$STATE_FILE" > "$tmp"
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$(date -Iseconds)" >> "$tmp"
  mv "$tmp" "$STATE_FILE"
}

if [ "$ACTION" = "--reset" ]; then
  : > "$STATE_FILE"
  echo "State cleared for $ROOT ($STATE_FILE)"
  exit 0
fi

if [ "$ACTION" = "--list" ]; then
  echo "State for $ROOT ($STATE_FILE):"
  column -t -s $'\t' "$STATE_FILE" 2>/dev/null || cat "$STATE_FILE"
  exit 0
fi

if [ "$ACTION" = "--accept" ]; then
  relpath="${3:?--accept requires an album relpath}"
  dir="$ROOT/$relpath"
  [ -d "$dir" ] || { echo "No such album dir: $dir" >&2; exit 1; }
  fp=$(fingerprint_album "$dir")
  set_stored "$relpath" "$fp" "accepted"
  echo "Marked accepted: $relpath"
  exit 0
fi

cd "$ROOT" || exit 1
scanned=0
skipped=0
flagged=0

while IFS= read -r dir; do
  shopt -s nullglob
  flacs=("$dir"/*.flac)
  shopt -u nullglob
  [ ${#flacs[@]} -eq 0 ] && continue

  relpath="${dir#./}"
  fp=$(fingerprint_album "$dir")
  stored_fp=$(get_stored_fp "$relpath")

  if [ -n "$stored_fp" ] && [ "$fp" = "$stored_fp" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  scanned=$((scanned + 1))
  if scan_album "$dir"; then
    set_stored "$relpath" "$fp" "clean"
  else
    flagged=$((flagged + 1))
    # Deliberately NOT recorded as clean — it'll be re-scanned and
    # re-reported every run until fixed or explicitly --accept'ed.
  fi
done < <(/usr/bin/find . -mindepth 1 -type d ! -iname "albumart_backup" | sort)

echo "---"
echo "scan_state: $scanned new/changed album(s) scanned ($flagged flagged), $skipped already-clean album(s) skipped"
