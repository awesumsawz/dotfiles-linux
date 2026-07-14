#!/usr/bin/env bash
#
# sync-to-sword.sh
#
# Copies NEW files and directories from the "jason-library" and
# "Library" folders to the "sword" volume on 10.0.30.1 over SSH. Files
# that already exist on the remote are left exactly as they are — nothing is
# overwritten and no duplicates are created. The source libraries are never
# modified.
#
# Usage:
#   ./sync-to-sword.sh            # perform the sync
#   ./sync-to-sword.sh --dry-run  # show what WOULD be copied, change nothing
#
set -euo pipefail

LIBRARIES=("jason-library" "Library")
REMOTE="jbiggs@10.0.30.1"
DEST_ROOT="/Volumes/sword/storage/Music"

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
    echo ">>> Done. Existing remote files were left untouched; only new files were copied."
fi
