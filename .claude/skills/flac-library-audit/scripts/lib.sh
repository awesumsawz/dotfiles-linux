#!/bin/bash
# Shared functions for the flac-library-audit skill's scripts.
# Source this file; do not execute it directly.

# Characters invalid in Windows/NTFS AND exFAT filenames. Filenames
# containing any of these can't be copied to the exFAT SAILBOAT drive
# (sync-to-sailboat.sh skips them with an rsync error), so the scanner
# flags them even when filename and tag agree exactly.
FORBIDDEN_NAME_CHARS='["<>:\\|?*]'

# scan_album <dir>
# Prints "##ALBUM## <dir>" followed by an indented FILE/ISSUE block for
# every .flac in <dir> that doesn't conform to the "## - Title.flac"
# standard (see SKILL.md for the full rule set). Prints just the
# ##ALBUM## line if everything in <dir> is clean.
# Returns 0 if the album is clean, 1 if any file had an issue.
scan_album() {
  local dir="$1"
  shopt -s nullglob
  local flacs=("$dir"/*.flac)
  shopt -u nullglob
  [ ${#flacs[@]} -eq 0 ] && return 0

  local dirty=0
  echo "##ALBUM## $dir"

  # Directory names (artist and album) must obey the same character rules
  # as filenames — a bad dir name blocks the exFAT sync for the whole album.
  if [[ "${dir#./}" =~ $FORBIDDEN_NAME_CHARS ]]; then
    dirty=1
    echo '  ISSUE: directory path contains characters invalid on Windows/exFAT (" < > : \ | ? *) — rename the artist/album directory (see sanitize_dirnames.sh)'
  fi

  local f base n t ar al dn dtot multidisc issues padn expected expected_slash title_safe title_safe_win i
  for f in "${flacs[@]}"; do
    base=$(basename "$f")
    n=$(metaflac --show-tag=TRACKNUMBER "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    t=$(metaflac --show-tag=TITLE "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    ar=$(metaflac --show-tag=ARTIST "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    al=$(metaflac --show-tag=ALBUM "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    dn=$(metaflac --show-tag=DISCNUMBER "$f" 2>/dev/null | sed -E 's/^[^=]+=//')
    dtot=$(metaflac --show-tag=DISCTOTAL "$f" 2>/dev/null | sed -E 's/^[^=]+=//')

    issues=()

    [ -z "$n" ] && issues+=("missing TRACKNUMBER tag")
    [ -z "$t" ] && issues+=("missing TITLE tag")
    [ -z "$ar" ] && issues+=("missing ARTIST tag")
    [ -z "$al" ] && issues+=("missing ALBUM tag")

    # Multi-disc albums (consolidated via consolidate_multidisc.sh) use
    # "<disc>-<track> - Title.flac" instead of plain "<track> - Title.flac".
    if [[ -n "$dtot" && "$dtot" =~ ^[0-9]+$ && "$dtot" -gt 1 ]]; then
      multidisc=1
    else
      multidisc=0
    fi

    if [ "$multidisc" -eq 1 ]; then
      if [[ ! "$base" =~ ^[0-9]+-[0-9]{2}\ -\ .+\.flac$ ]]; then
        issues+=("filename doesn't match '<disc>-## - Title.flac' pattern (multi-disc album)")
      fi
    elif [[ ! "$base" =~ ^[0-9]{2}\ -\ .+\.flac$ ]]; then
      issues+=("filename doesn't match '## - Title.flac' pattern")
    fi

    if [[ "$base" =~ $FORBIDDEN_NAME_CHARS ]]; then
      issues+=('filename contains characters invalid on Windows/exFAT (" < > : \ | ? *) — sync to the exFAT SAILBOAT drive skips these files')
    fi

    if [[ "$n" =~ ^[0-9]+/[0-9]+$ ]]; then
      issues+=("TRACKNUMBER uses combined 'N/total' format, should split into TRACKNUMBER+TRACKTOTAL")
    elif [[ -n "$n" && "$n" =~ ^[0-9]+$ && ! "$n" =~ ^[0-9]{2}$ ]]; then
      issues+=("TRACKNUMBER tag isn't zero-padded to 2 digits (is '$n') — filename may look right but the tag itself sorts lexicographically wrong in some players")
    fi

    if [[ "$t" =~ ^[[:space:]] || "$t" =~ [[:space:]]$ || "$t" =~ [[:space:]][[:space:]] ]]; then
      issues+=("TITLE tag has leading/trailing/doubled whitespace")
    fi
    if [[ "$al" =~ ^[[:space:]] || "$al" =~ [[:space:]]$ || "$al" =~ [[:space:]][[:space:]] ]]; then
      issues+=("ALBUM tag has leading/trailing/doubled whitespace")
    fi

    if [ -n "$n" ] && [ -n "$t" ] && [[ "$n" =~ ^[0-9]+$ ]]; then
      # NOTE: force base-10 with 10#, else bash misreads a leading-zero
      # track number ("08") as an invalid octal literal.
      padn=$(printf "%02d" "$((10#$n))" 2>/dev/null)
      title_safe="${t//\//-}"
      title_safe_win="${title_safe//[\"\<\>:\\|?*]/_}"
      if [ "$multidisc" -eq 1 ] && [ -n "$dn" ] && [[ "$dn" =~ ^[0-9]+$ ]]; then
        expected="${dn}-${padn} - ${t}.flac"
        expected_slash="${dn}-${padn} - ${title_safe}.flac"
        if [ "$base" != "$expected" ] && [ "$base" != "$expected_slash" ] && [ "$base" != "${dn}-${padn} - ${title_safe_win}.flac" ]; then
          issues+=("filename/tag mismatch (expected '${dn}-${padn} - ${title_safe_win}.flac')")
        fi
      else
        expected="${padn} - ${t}.flac"
        expected_slash="${padn} - ${title_safe}.flac"
        if [ "$base" != "$expected" ] && [ "$base" != "$expected_slash" ] && [ "$base" != "${padn} - ${title_safe_win}.flac" ]; then
          issues+=("filename/tag mismatch (expected '${padn} - ${title_safe_win}.flac')")
        fi
      fi
    fi

    if [ ${#issues[@]} -gt 0 ]; then
      dirty=1
      echo "  FILE: $base"
      echo "    tags: track='$n' title='$t' artist='$ar' album='$al'"
      for i in "${issues[@]}"; do
        echo "    ISSUE: $i"
      done
    fi
  done
  return $dirty
}

# fingerprint_album <dir>
# Prints a hash summarizing the .flac filenames + sizes in <dir>, stable
# across re-runs as long as no file is added/removed/renamed/resized.
# Used to detect "this album hasn't changed since last time" without
# needing per-file mtime bookkeeping.
fingerprint_album() {
  local dir="$1"
  (
    shopt -s nullglob
    cd "$dir" || exit 1
    for f in *.flac; do
      printf '%s\t%s\n' "$f" "$(stat -c%s "$f" 2>/dev/null)"
    done
  ) | sort | sha256sum | cut -d' ' -f1
}
