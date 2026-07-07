#!/usr/bin/env bash
#
# sync-to-sailboat.sh
#
# Copies NEW files and directories from the "Jason Library - CDs" and
# "Library" folders to the attached "SAILBOAT" drive's Music folder. Files
# that already exist on the drive are left exactly as they are — nothing is
# overwritten and no duplicates are created. The source libraries are never
# modified.
#
# Usage:
#   ./sync-to-sailboat.sh            # perform the sync
#   ./sync-to-sailboat.sh --dry-run  # show what WOULD be copied, change nothing
#
set -euo pipefail

LIBRARIES=("Jason Library - CDs" "Library")
DEST_ROOT="/run/media/$USER/SAILBOAT/Music"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    DRY_RUN="--dry-run"
    echo ">>> DRY RUN — no files will actually be copied."
fi

# --- Sanity checks -----------------------------------------------------------
for LIB in "${LIBRARIES[@]}"; do
    if [[ ! -d "$HOME/Music/$LIB" ]]; then
        echo "ERROR: source folder not found: $HOME/Music/$LIB" >&2
        exit 1
    fi
done

if ! mountpoint -q "/run/media/$USER/SAILBOAT"; then
    echo "ERROR: SAILBOAT drive does not appear to be mounted at /run/media/$USER/SAILBOAT" >&2
    echo "       Plug it in / mount it and try again." >&2
    exit 1
fi

# --- Sync --------------------------------------------------------------------
# -r  recurse into directories
# -t  preserve modification times (avoids needless re-checks on re-runs)
# -v  verbose (list what is transferred)
# -h  human-readable sizes
# --progress            per-file progress
# --ignore-existing     skip any file already present on the drive (no overwrite,
#                       no duplicates) — only genuinely new files are copied
# --modify-window=2     tolerate timestamp resolution quirks on exfat
# --exclude             skip macOS/Rockbox junk files
#
# Note: we deliberately do NOT use -a (archive). The SAILBOAT volume is exFAT
# and does not store Unix permissions or ownership, so preserving them
# only produces errors.
for LIB in "${LIBRARIES[@]}"; do
    SRC="$HOME/Music/$LIB"
    DEST="$DEST_ROOT/$LIB"

    echo
    echo ">>> Syncing '$LIB'..."
    mkdir -p "$DEST"

    rsync -rtvh --progress \
        --ignore-existing \
        --modify-window=2 \
        --exclude='.DS_Store' \
        --exclude='._*' \
        --exclude='.Trash-*' \
        $DRY_RUN \
        "$SRC"/ "$DEST"/
done

echo
echo ">>> Done. Existing SAILBOAT files were left untouched; only new files were copied."
