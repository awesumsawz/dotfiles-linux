#!/bin/bash
# Moves an audited album directory into the canonical library
# (~/Music/Library/<Artist>/<Album> by default). Run this only AFTER the
# album scans clean (or has been explicitly accepted) — this script does
# no auditing of its own.
#
# Artist is taken from the album dir's parent directory name (staging
# areas mirror the Artist/Album layout). If the album isn't nested under
# an artist directory, pass --artist to name it explicitly.
#
# Refuses to move: an album dir with no .flac files, a name (artist or
# album) still containing forbidden characters (fix with
# sanitize_dirnames.sh / rename_from_tags.sh first), or onto an existing
# destination album directory.
#
# Note for scan_state.sh users: the album leaves its staging root's state
# behind as a harmless orphan row, and appears as "new" under the library
# root — re-run scan_state.sh on the library root afterwards so it gets
# recorded clean there (and re-issue --accept under the new root for
# accepted exceptions like Various Artists albums).
#
# Usage:
#   move_to_library.sh <album-dir> [--library <root>] [--artist <name>] [--dry-run]
set -uo pipefail
album_dir="${1:?Usage: move_to_library.sh <album-dir> [--library <root>] [--artist <name>] [--dry-run]}"
shift

library="$HOME/Music/Library"
artist=""
dry=""
while [ $# -gt 0 ]; do
  case "$1" in
    --library) library="${2:?--library needs a path}"; shift 2 ;;
    --artist)  artist="${2:?--artist needs a name}"; shift 2 ;;
    --dry-run|-n) dry=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

album_dir="$(realpath -- "$album_dir")" || exit 1
[ -d "$album_dir" ] || { echo "Not a directory: $album_dir" >&2; exit 1; }
[ -d "$library" ] || { echo "Library root does not exist: $library" >&2; exit 1; }

album="$(basename -- "$album_dir")"
[ -n "$artist" ] || artist="$(basename -- "$(dirname -- "$album_dir")")"

case "$album_dir" in
  "$library"/*) echo "Album is already inside the library: $album_dir" >&2; exit 1 ;;
esac

flac_count=$(/usr/bin/find "$album_dir" -maxdepth 1 -type f -name '*.flac' | wc -l)
if [ "$flac_count" -eq 0 ]; then
  echo "REFUSING: no .flac files directly in '$album_dir' — is this really an album dir?" >&2
  exit 1
fi

for name in "$artist" "$album"; do
  if [[ "$name" == *[\"\<\>:\\\|?*]* ]]; then
    echo "REFUSING: '$name' contains forbidden characters (\" < > : \\ | ? *)." >&2
    echo "Run sanitize_dirnames.sh on the staging root first, then retry." >&2
    exit 1
  fi
done

dest="$library/$artist/$album"
if [ -e "$dest" ]; then
  echo "REFUSING to move '$album_dir' -> '$dest' (destination already exists)" >&2
  exit 1
fi

if [ -n "$dry" ]; then
  echo "would move: $album_dir -> $dest"
  exit 0
fi

mkdir -p -- "$library/$artist" || exit 1
mv -n -- "$album_dir" "$dest" || exit 1
echo "moved: $album_dir -> $dest"

# Tidy up an emptied artist dir left behind in staging (ignore failure —
# non-empty dirs stay put).
rmdir -- "$(dirname -- "$album_dir")" 2>/dev/null && \
  echo "removed emptied staging artist dir: $(dirname -- "$album_dir")"

echo "Reminder: re-run scan_state.sh \"$library\" so the album is recorded clean under the library root."
