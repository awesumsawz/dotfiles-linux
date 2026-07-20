#!/usr/bin/env bash
#
# sync-to-plex.sh
#
# Mirrors the "Library" folder's contents to the Plex music share on
# 10.0.30.202 over SSH: new files are copied over, and files that no longer
# exist locally are DELETED from the remote. Files present on both sides are
# left exactly as they are — nothing is overwritten. The source library is
# never modified.
#
# Unlike the other sync scripts, the contents of Library are copied directly
# into the destination folder (not nested inside a "Library" subfolder) since
# the remote's music folder IS the library.
#
# Usage:
#   ./sync-to-plex.sh            # perform the sync
#   ./sync-to-plex.sh --dry-run  # show what WOULD be copied, change nothing
#
set -euo pipefail

SRC="$HOME/Music/Library"
REMOTE="jbiggs@10.0.30.202"
DEST="/mnt/swimming-pool/plex/music"

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
# With --delete, an empty source would wipe the remote copy — refuse to run.
if [[ -z "$(ls -A "$SRC")" ]]; then
    echo "ERROR: source folder is empty: $SRC — refusing to mirror it" >&2
    echo "       (that would delete the entire music copy on the remote)." >&2
    exit 1
fi

if ! ssh -o ConnectTimeout=5 "$REMOTE" "[ -d '$DEST' ]"; then
    echo "ERROR: cannot reach $REMOTE or $DEST does not exist there." >&2
    echo "       Check that the host is up, SSH works, and the share is mounted." >&2
    exit 1
fi

# --- Sync --------------------------------------------------------------------
# -r  recurse into directories
# -t  preserve modification times (avoids needless re-checks on re-runs)
# -v  verbose (list what is transferred)
# -h  human-readable sizes
# --progress            per-file progress
# --ignore-existing     skip any file already present on the remote (no overwrite,
#                       no duplicates) — only genuinely new files are copied
# --delete              remove files from the remote that no longer exist in the
#                       local library (local copy is the source of truth);
#                       excluded patterns below are protected from deletion
# --modify-window=2     tolerate timestamp resolution quirks across filesystems
# --exclude             skip macOS/Rockbox junk files
#
# Note: we deliberately do NOT use -a (archive). The remote volume may not
# store Unix permissions or ownership the same way, so preserving them
# only produces errors.
echo
echo ">>> Syncing Library contents into $REMOTE:$DEST ..."
ssh "$REMOTE" "mkdir -p '$DEST'"

rc=0
rsync -rtvh --progress \
    --ignore-existing \
    --delete \
    --modify-window=2 \
    --exclude='.DS_Store' \
    --exclude='._*' \
    --exclude='.Trash-*' \
    $DRY_RUN \
    "$SRC"/ "$REMOTE:$DEST"/ || rc=$?

echo
# Exit code 23 = "some files could not be transferred" (e.g. names containing
# characters the remote filesystem forbids). Warn but don't fail the run.
if [[ $rc -eq 23 ]]; then
    echo "WARNING: some files could not be copied (see rsync errors above)." >&2
    echo ">>> Done, but some files were skipped due to errors. Rename those files"
    echo ">>> in the source library and re-run to include them."
elif [[ $rc -ne 0 ]]; then
    echo "ERROR: rsync failed (exit code $rc)." >&2
    exit "$rc"
else
    echo ">>> Done. New files were copied and locally-deleted files were removed from the remote."
fi
