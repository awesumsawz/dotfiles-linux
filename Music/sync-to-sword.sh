#!/usr/bin/env bash
#
# sync-to-sword.sh
#
# Mirrors the "Library" folder to the "sword" volume on 10.0.30.1 over SSH:
# new files are copied over, and files that no longer exist locally are DELETED
# from the remote. Files present on both sides are left exactly as they are —
# nothing is overwritten. The source library is never modified.
#
# Usage:
#   ./sync-to-sword.sh            # perform the sync
#   ./sync-to-sword.sh --dry-run  # show what WOULD be copied, change nothing
#
set -euo pipefail

LIBRARIES=("Library")
REMOTE="jbiggs@10.0.30.1"
DEST_ROOT="/Volumes/sword/storage/Music"

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
    # With --delete, an empty source would wipe the remote copy — refuse to run.
    if [[ -z "$(ls -A "$HOME/Music/$LIB")" ]]; then
        echo "ERROR: source folder is empty: $HOME/Music/$LIB — refusing to mirror it" >&2
        echo "       (that would delete the entire '$LIB' copy on the remote)." >&2
        exit 1
    fi
done

if ! ssh -o ConnectTimeout=5 "$REMOTE" "[ -d '$DEST_ROOT' ]"; then
    echo "ERROR: cannot reach $REMOTE or $DEST_ROOT does not exist there." >&2
    echo "       Check that the host is up, SSH works, and the sword volume is mounted." >&2
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
WARNINGS=0
for LIB in "${LIBRARIES[@]}"; do
    SRC="$HOME/Music/$LIB"
    DEST="$DEST_ROOT/$LIB"

    echo
    echo ">>> Syncing '$LIB'..."
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

    # Exit code 23 = "some files could not be transferred" (e.g. names containing
    # characters the remote filesystem forbids). Warn but keep syncing the
    # remaining libraries instead of aborting the whole run.
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
    echo ">>> Done, but some files were skipped due to errors (likely characters the"
    echo ">>> remote filesystem does not allow in filenames). Rename those files"
    echo ">>> in the source library and re-run to include them."
else
    echo ">>> Done. New files were copied and locally-deleted files were removed from the remote."
fi
