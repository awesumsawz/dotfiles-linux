#!/bin/bash
# Audits a FLAC music library for filename/metadata consistency.
# Full stateless scan — checks every album every time. For a library
# you re-scan repeatedly as you add music, use scan_state.sh instead so
# already-clean albums are skipped.
#
# Target filename format: "## - <track name>.flac" (2-digit zero-padded
# track number, literal " - ", the TITLE tag text, ".flac").
#
# Usage: audit.sh <library-root>
#   Prints one "##ALBUM## <path>" line per album dir (any dir directly
#   containing .flac files, skipping "albumart_backup" dirs), followed by
#   an indented block per file that has an issue. Albums with no issues
#   print only the ##ALBUM## line, so grepping for albums followed by an
#   ISSUE line tells you what still needs attention.
#
# This script MUST be run via bash (not sourced/pasted into an interactive
# zsh shell) because it relies on BASH_REMATCH for regex captures. See the
# skill's SKILL.md "Environment gotchas" section for why.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

ROOT="${1:?Usage: audit.sh <library-root>}"
cd "$ROOT" || exit 1

while IFS= read -r dir; do
  scan_album "$dir"
done < <(/usr/bin/find . -mindepth 1 -type d ! -iname "albumart_backup" | sort)
