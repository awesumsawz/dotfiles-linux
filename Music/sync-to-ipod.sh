#!/usr/bin/env bash
#
# sync-to-ipod.sh
#
# Mirrors the "jason-library" folder to the attached iPod's Music/jason-library
# folder: new files are copied over, and files that no longer exist locally are
# DELETED from the iPod. Files present on both sides are left exactly as they
# are — nothing is overwritten. The source library is never modified.
#
# Usage:
#   ./sync-to-ipod.sh            # perform the sync
#   ./sync-to-ipod.sh --dry-run  # show what WOULD be copied, change nothing
#
set -euo pipefail

SRC="$HOME/Music/jason-library"
DEST="/run/media/$USER/IPOD/Music/jason-library"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    DRY_RUN="--dry-run"
    echo ">>> DRY RUN — no files will actually be copied or deleted."
fi

# --- Sanity checks -----------------------------------------------------------
if [[ ! -d "$SRC" ]]; then
    echo "ERROR: source folder not found: $SRC" >&2
    exit 1
fi

# With --delete, an empty source would wipe the iPod library — refuse to run.
if [[ -z "$(ls -A "$SRC")" ]]; then
    echo "ERROR: source folder is empty: $SRC — refusing to mirror it (that would" >&2
    echo "       delete the entire library on the iPod)." >&2
    exit 1
fi

if ! mountpoint -q "/run/media/$USER/IPOD"; then
    echo "ERROR: iPod does not appear to be mounted at /run/media/$USER/IPOD" >&2
    echo "       Plug it in / mount it and try again." >&2
    exit 1
fi

# --- Sync --------------------------------------------------------------------
# -r  recurse into directories
# -t  preserve modification times (avoids needless re-checks on re-runs)
# -v  verbose (list what is transferred)
# -h  human-readable sizes
# --progress            per-file progress
# --ignore-existing     skip any file already present on the iPod (no overwrite,
#                       no duplicates) — only genuinely new files are copied
# --delete              remove files from the iPod that no longer exist in the
#                       local library (local copy is the source of truth);
#                       excluded patterns below are protected from deletion
# --modify-window=2     tolerate the 2-second timestamp resolution of vfat/FAT32
# --exclude             skip macOS/Rockbox junk files
#
# Note: we deliberately do NOT use -a (archive). The iPod is a FAT32 (vfat)
# volume that cannot store Unix permissions or ownership, so preserving them
# only produces errors.
echo ">>> Syncing: $SRC -> $DEST"
mkdir -p "$DEST"
rsync -rtvh --progress \
    --ignore-existing \
    --delete \
    --modify-window=2 \
    --exclude='.DS_Store' \
    --exclude='._*' \
    --exclude='.Trash-*' \
    $DRY_RUN \
    "$SRC"/ "$DEST"/

echo
echo ">>> Done. New files were copied and locally-deleted files were removed from the iPod."
