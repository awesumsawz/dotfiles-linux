#!/usr/bin/env bash
#
# sync-to-sailboat.sh
#
# Mirrors the "Library" folder to the attached "SAILBOAT" drive's Music folder:
# new files are copied over, and files that no longer exist locally are DELETED
# from the drive. Files present on both sides are left exactly as they are —
# nothing is overwritten. The source library is never modified.
#
# Usage:
#   ./sync-to-sailboat.sh            # perform the sync
#   ./sync-to-sailboat.sh --dry-run  # show what WOULD be copied, change nothing
#
set -euo pipefail

LIBRARIES=("Library")
DEST_ROOT="/run/media/$USER/SAILBOAT/Music"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    DRY_RUN="--dry-run"
    echo ">>> DRY RUN — no files will actually be copied or deleted."
fi

# --- Sanity checks -----------------------------------------------------------
for LIB in "${LIBRARIES[@]}"; do
    if [[ ! -d "$HOME/Music/$LIB" ]]; then
        echo "ERROR: source folder not found: $HOME/Music/$LIB" >&2
        exit 1
    fi
    # With --delete, an empty source would wipe the drive's copy — refuse to run.
    if [[ -z "$(ls -A "$HOME/Music/$LIB")" ]]; then
        echo "ERROR: source folder is empty: $HOME/Music/$LIB — refusing to mirror it" >&2
        echo "       (that would delete the entire '$LIB' copy on the drive)." >&2
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
# --delete              remove files from the drive that no longer exist in the
#                       local library (local copy is the source of truth);
#                       excluded patterns below are protected from deletion
# --modify-window=2     tolerate timestamp resolution quirks on exfat
# --exclude             skip macOS/Rockbox junk files
#
# Note: we deliberately do NOT use -a (archive). The SAILBOAT volume is exFAT
# and does not store Unix permissions or ownership, so preserving them
# only produces errors.
WARNINGS=0
for LIB in "${LIBRARIES[@]}"; do
    SRC="$HOME/Music/$LIB"
    DEST="$DEST_ROOT/$LIB"

    echo
    echo ">>> Syncing '$LIB'..."
    mkdir -p "$DEST"

    rc=0
    rsync -rtvh --progress \
        --ignore-existing \
        --delete \
        --modify-window=2 \
        --exclude='.DS_Store' \
        --exclude='._*' \
        --exclude='.Trash-*' \
        $DRY_RUN \
        "$SRC"/ "$DEST"/ || rc=$?

    # Exit code 23 = "some files could not be transferred" (e.g. names containing
    # characters exFAT forbids, like " or ?). Warn but keep syncing the remaining
    # libraries instead of aborting the whole run.
    if [[ $rc -eq 23 ]]; then
        echo "WARNING: some files in '$LIB' could not be copied (see rsync errors above)." >&2
        WARNINGS=1
    elif [[ $rc -ne 0 ]]; then
        echo "ERROR: rsync failed for '$LIB' (exit code $rc)." >&2
        exit "$rc"
    fi
done

echo
if [[ $WARNINGS -ne 0 ]]; then
    echo ">>> Done, but some files were skipped due to errors (likely characters exFAT"
    echo ">>> does not allow in filenames, such as \" ? : * < > |). Rename those files"
    echo ">>> in the source library and re-run to include them."
else
    echo ">>> Done. New files were copied and locally-deleted files were removed from SAILBOAT."
fi
