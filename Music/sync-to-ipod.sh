#!/usr/bin/env bash
#
# sync-to-ipod.sh
#
# Copies NEW files and directories from the "Jason Library - CDs" folder to the
# attached iPod's Music folder. Files that already exist on the iPod are left
# exactly as they are — nothing is overwritten and no duplicates are created.
# The source library is never modified.
#
# Usage:
#   ./sync-to-ipod.sh            # perform the sync
#   ./sync-to-ipod.sh --dry-run  # show what WOULD be copied, change nothing
#
set -euo pipefail

SRC="$HOME/Music/Jason Library - CDs"
DEST="/run/media/$USER/IPOD/Music"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    DRY_RUN="--dry-run"
    echo ">>> DRY RUN — no files will actually be copied."
fi

# --- Sanity checks -----------------------------------------------------------
if [[ ! -d "$SRC" ]]; then
    echo "ERROR: source folder not found: $SRC" >&2
    exit 1
fi

if ! mountpoint -q "/run/media/$USER/IPOD"; then
    echo "ERROR: iPod does not appear to be mounted at /run/media/$USER/IPOD" >&2
    echo "       Plug it in / mount it and try again." >&2
    exit 1
fi

mkdir -p "$DEST"

# --- Sync --------------------------------------------------------------------
# -r  recurse into directories
# -t  preserve modification times (avoids needless re-checks on re-runs)
# -v  verbose (list what is transferred)
# -h  human-readable sizes
# --progress            per-file progress
# --ignore-existing     skip any file already present on the iPod (no overwrite,
#                       no duplicates) — only genuinely new files are copied
# --modify-window=2     tolerate the 2-second timestamp resolution of vfat/FAT32
# --exclude             skip macOS/Rockbox junk files
#
# Note: we deliberately do NOT use -a (archive). The iPod is a FAT32 (vfat)
# volume that cannot store Unix permissions or ownership, so preserving them
# only produces errors.
rsync -rtvh --progress \
    --ignore-existing \
    --modify-window=2 \
    --exclude='.DS_Store' \
    --exclude='._*' \
    --exclude='.Trash-*' \
    $DRY_RUN \
    "$SRC"/ "$DEST"/

echo
echo ">>> Done. Existing iPod files were left untouched; only new files were copied."
