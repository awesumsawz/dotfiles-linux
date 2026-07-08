#!/bin/bash
# Merges a multi-disc album into a single flat directory with filenames
# prefixed "<disc>-<track> - <title>.flac" (disc number unpadded, track
# zero-padded to 2 digits, title from the TITLE tag with "/" -> "-").
#
# Two supported starting layouts:
#   1. Album dir contains "CD N" / "CD N - ..." / "Disc N" subdirectories
#      (each holding that disc's .flac files, maybe a folder.jpg). Every
#      file is moved up into the album dir itself and renamed; each
#      file's DISCNUMBER/DISCTOTAL tags are corrected to match the disc
#      folder it physically came from and the total number of disc
#      folders found (TRACKNUMBER is left disc-relative, untouched).
#      Non-flac files (cover art etc.) are moved up too; a name collision
#      across discs is disambiguated with a "-<disc>" suffix. Emptied
#      disc subdirectories are then removed.
#   2. Album dir is already flat but uses continuous track numbering
#      instead of a disc prefix (a pre-existing multi-disc-in-one-folder
#      case). Files are renamed in place using their own existing
#      DISCNUMBER/TRACKNUMBER/TITLE tags — nothing is moved, and a file
#      missing any of those three tags is skipped with a warning rather
#      than guessed at.
#
# Title text is also sanitized for characters invalid in Windows/NTFS
# filenames (< > : " \ | ? *, replaced with "_") since this library is
# played from Windows-based players (foobar2000/MediaMonkey) — "/" gets
# its own substitution to "-" per existing library convention, everything
# else invalid gets "_" to match how those characters are already handled
# elsewhere in the library (e.g. a dropped "?" leaves a trailing "_").
#
# Usage: consolidate_multidisc.sh <album-dir>
set -uo pipefail
dir="${1:?Usage: consolidate_multidisc.sh <album-dir>}"
cd "$dir" || exit 1
shopt -s nullglob

disc_dirs=()
while IFS= read -r sub; do
  disc_dirs+=("$sub")
done < <(/usr/bin/find . -mindepth 1 -maxdepth 1 -type d -iregex '.*/\(cd\|disc\)[ _-]*[0-9]+.*' | sort)

if [ ${#disc_dirs[@]} -gt 0 ]; then
  total=${#disc_dirs[@]}
  for sub in "${disc_dirs[@]}"; do
    base_sub=$(basename "$sub")
    disc=""
    if [[ "$base_sub" =~ [Cc][Dd][^0-9]*([0-9]+) ]]; then
      disc="${BASH_REMATCH[1]}"
    elif [[ "$base_sub" =~ [Dd]isc[^0-9]*([0-9]+) ]]; then
      disc="${BASH_REMATCH[1]}"
    fi
    if [ -z "$disc" ]; then
      echo "Could not determine disc number for $sub, skipping" >&2
      continue
    fi

    for f in "$sub"/*.flac; do
      tn=$(metaflac --show-tag=TRACKNUMBER "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
      t=$(metaflac --show-tag=TITLE "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
      dn=$(metaflac --show-tag=DISCNUMBER "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
      dtot=$(metaflac --show-tag=DISCTOTAL "$f" 2>/dev/null | sed -E 's/^[^=]+=//')

      if [ -z "$tn" ] || [ -z "$t" ]; then
        echo "SKIP (missing TRACKNUMBER/TITLE tag): $f" >&2
        continue
      fi

      if [ "$dn" != "$disc" ] || [ "$dtot" != "$total" ]; then
        metaflac --remove-tag=DISCNUMBER --remove-tag=DISCTOTAL \
          --set-tag="DISCNUMBER=$disc" --set-tag="DISCTOTAL=$total" "$f"
      fi

      padn=$(printf "%02d" "$((10#$tn))" 2>/dev/null)
      title_safe="${t//\//-}"
      title_safe="${title_safe//[\"\<\>:\\|?*]/_}"
      newname="${disc}-${padn} - ${title_safe}.flac"

      if [ -e "$newname" ]; then
        echo "REFUSING to overwrite existing '$newname' (from $f)" >&2
        continue
      fi
      mv -n -- "$f" "./$newname"
      echo "moved: $f -> $newname"
    done

    for other in "$sub"/*; do
      [ -e "$other" ] || continue
      oname=$(basename "$other")
      target="$oname"
      if [ -e "$target" ]; then
        target="${oname%.*}-${disc}.${oname##*.}"
      fi
      mv -n -- "$other" "./$target"
      echo "moved: $other -> $target"
    done

    rmdir "$sub" 2>/dev/null && echo "removed empty dir: $sub" || echo "WARNING: $sub not empty, left in place" >&2
  done
else
  for f in *.flac; do
    dn=$(metaflac --show-tag=DISCNUMBER "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    tn=$(metaflac --show-tag=TRACKNUMBER "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    t=$(metaflac --show-tag=TITLE "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    if [ -z "$dn" ] || [ -z "$tn" ] || [ -z "$t" ]; then
      echo "SKIP (missing DISCNUMBER/TRACKNUMBER/TITLE tag): $f" >&2
      continue
    fi
    padn=$(printf "%02d" "$((10#$tn))" 2>/dev/null)
    title_safe="${t//\//-}"
    title_safe="${title_safe//[\"\<\>:\\|?*]/_}"
    newname="${dn}-${padn} - ${title_safe}.flac"
    [ "$f" = "$newname" ] && continue
    if [ -e "$newname" ]; then
      echo "REFUSING to overwrite existing '$newname' (from $f)" >&2
      continue
    fi
    mv -n -- "$f" "$newname"
    echo "renamed: $f -> $newname"
  done
fi
shopt -u nullglob
