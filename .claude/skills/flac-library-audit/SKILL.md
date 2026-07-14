---
name: flac-library-audit
description: >
  Use when the user wants to audit, clean up, or standardize filenames and
  metadata in a local FLAC music library — e.g. "make sure this album
  follows the ## - title format", "confirm metadata matches for all
  albums", "fix the tags on this rip". Covers: filename/tag consistency
  checks across an artist or whole library, fixing garbled/duplicated
  filenames from bad rips, fixing truncated or placeholder tags, and
  bulk renaming. Not for streaming-service metadata or non-FLAC formats.
---

# FLAC Library Audit

Standardize a FLAC library so every track's filename is `## - <track name>.flac`
(2-digit zero-padded track number, literal ` - `, the track title, `.flac`)
and the file's own TRACKNUMBER/TITLE tags agree with that filename.

**Character restriction (files AND directories):** no name in the library
may contain any of `" < > : \ | ? *`. These are invalid on Windows/NTFS
and on exFAT — the SAILBOAT drive this library syncs to is exFAT, and
`sync-to-sailboat.sh` cannot copy such files (rsync "Invalid argument"
errors), silently leaving them off the drive. The scanner flags them even
when filename and tags agree exactly. Convention when fixing: `/` in a
tag becomes `-` in the name; each of the other invalid characters becomes
`_`. Tags themselves keep the real punctuation — only names are
sanitized. Directory names get the same treatment via
`sanitize_dirnames.sh` (see the scripts table).

## Environment gotchas (check these first, every time)

These cost real time in past runs — verify them before writing loops:

1. **The interactive shell may be zsh, not bash.** Confirm with
   `echo "bash=$BASH_VERSION zsh=$ZSH_VERSION"`. If zsh: inline `[[ str =~
   regex ]]` does NOT populate `BASH_REMATCH` the way bash does, so any
   loop using regex capture groups (splitting a filename into track
   number + title, etc.) will silently produce empty captures. Fix: write
   the loop to a `.sh` file with a `#!/bin/bash` shebang, `chmod +x`, and
   execute it by path — never paste bash-specific regex capture logic
   directly as an inline command when the shell is zsh.
2. **`cd` may be hijacked by zoxide.** If zoxide is configured, plain
   `cd "/some/path"` can silently fuzzy-match to the wrong directory
   instead of doing a literal cd, especially if that exact path hasn't
   been visited before ("zoxide: no match found" while staying put).
   Always confirm location with `pwd` after any `cd`, or bypass zoxide
   entirely with `builtin cd "/exact/path"`.
3. **`ls`/`find` may be aliased to something that prints nothing when
   piped** (e.g. eza in a non-interactive context). If `ls | head` or a
   piped `find` returns suspiciously empty, retry with `/bin/ls` or
   `/usr/bin/find` directly.

## Workflow

1. **Survey the tree.** `find <root> -mindepth 1 -maxdepth 2 -type d` to
   see artist/album structure. Watch for `albumart_backup` subdirs (skip
   them) and multi-disc albums sharing one flat folder (see caveat below).

2. **Scan.** For a library the user adds to over time, prefer the
   incremental scanner over the plain audit script — it remembers what
   was already reviewed so repeat runs only surface what's new:
   ```
   scripts/scan_state.sh "<library-root>"
   ```
   This skips any album whose `.flac` contents (filenames + sizes) are
   unchanged since it was last recorded clean/accepted, and prints the
   same `##ALBUM##`/`FILE`/`ISSUE` block as below for everything else. An
   album that still has issues after being scanned is deliberately *not*
   recorded as clean, so it resurfaces on every run until it's fixed or
   explicitly accepted (see step 4). State lives outside the music
   library, under this skill's own `state/` dir, keyed by a hash of the
   library root's absolute path — it never touches the user's files.

   Use the plain, stateless `scripts/audit.sh "<library-root>"` instead
   when you want a full re-check regardless of history (e.g. right after
   changing the audit logic itself, or a one-off "how healthy is this
   whole library" question). Its output format is identical:
   ```
   scripts/audit.sh "<library-root>" > /tmp/audit_output.txt
   awk '/^##ALBUM##/{a=$0;h=0} /ISSUE:/{if(!h){print a;h=1}}' /tmp/audit_output.txt
   ```
   **Fingerprint caveat:** the fingerprint is filename+size, not a content
   hash of the tags. `metaflac` usually reuses an existing PADDING block
   for small tag edits (e.g. zero-padding a TRACKNUMBER), so file size
   often doesn't change — meaning a pure tag-only fix on an
   already-accepted album may not flip its fingerprint and won't force a
   rescan. This is harmless as long as the fix was applied directly to
   every affected file (verify with a targeted `metaflac --show-tag`
   sweep rather than trusting scan_state alone), but don't rely on
   scan_state to *discover* that a tag-only bug exists across the
   library — a targeted grep-style sweep (see the TRACKNUMBER padding
   check below) is still needed after changing the audit logic itself.

   Either way, read the full block for each flagged album
   (`grep -A20 "<album path>" ...`) rather than dumping the whole file
   into context.

3. **Triage each flagged file into one of these buckets** before touching
   anything:
   - **Genuinely broken tags** — placeholder values (`Track 1`, `Unknown
     Artist`, `Unknown Album`) or truncated titles need real data filled
     in (check the official tracklist, see step 5) — no script can guess
     these. Two narrower cases ARE mechanical and have scripts:
     whitespace bugs (leading/trailing/doubled spaces in TITLE/ALBUM/
     ARTIST) → `scripts/fix_tag_whitespace.sh <album-dir>`; combined
     `TRACKNUMBER=N/total` / `DISCNUMBER=N/total`, or a plain unpadded
     `TRACKNUMBER` (`1` instead of `01`), that should be a zero-padded
     2-digit `TRACKNUMBER` (+ `TRACKTOTAL`/`DISCNUMBER`/`DISCTOTAL` when
     combined) → `scripts/fix_tracknumber_format.sh <album-dir>`. Always
     fix all of these — they're objectively wrong, not stylistic. An
     unpadded TRACKNUMBER is easy to miss because the *filename* can look
     perfectly correct (`01 - Title.flac`) while the tag itself still
     reads `1` — some players sort by the tag lexicographically (1, 10,
     11, ..., 2, 3, ...) when it isn't zero-padded, which displays tracks
     in the wrong order even though every filename is fine. This can slip
     past a rename-only fix (e.g. `rename_to_standard.sh`, which never
     touches tags) — after any batch of separator-only renames, spot-check
     a file's actual `TRACKNUMBER` tag, not just its filename.
   - **Garbled/duplicated filenames** from a bad rip (metadata fields
     concatenated into the filename over and over). The TITLE/TRACKNUMBER
     tags are usually still clean in this case — verify with `metaflac
     --list --block-type=VORBIS_COMMENT <file>`, fix any bad tags first,
     then run `scripts/rename_from_tags.sh <album-dir>` to regenerate
     filenames from the now-correct tags.
   - **Wrong separator only** (`01. Title`, `01-Title`, `01_Title` instead
     of `01 - Title`), tags otherwise fine — just run
     `scripts/rename_to_standard.sh <album-dir>`.
   - **Forbidden characters in a file or directory name** (`" < > : \ |
     ? *`) — always a bug, never a style choice: the exFAT SAILBOAT sync
     cannot copy these at all. Fix files with `rename_from_tags.sh`
     (regenerates the name from tags with the sanitizer applied) and
     directories with `sanitize_dirnames.sh`. Leave the *tags* holding
     the real punctuation.
   - **Filename simplifies the tag** (dropped `?`, `&` spelled out as
     "and", `(feat. ...)` credits omitted, minor casing differences). For
     characters in the forbidden set above, removal is mandatory — the
     only latitude is whether the user prefers the character dropped
     entirely (e.g. `Am I Savage.flac`) or replaced with `_` (the
     scripts' default, `Am I Savage_.flac`); either passes the sync, and
     a dropped-char filename will still show as a "filename/tag mismatch"
     — `--accept` it (step 5) if the user prefers that form. For
     everything else ("and" for `&`, omitted feat credits, casing) it's a
     real style choice — **ask the user** once per session before
     mass-renaming. Last time this was asked the user chose to keep
     simplified filenames and only fix stray artifacts left behind (e.g.
     a dangling trailing space where a `?` was dropped). Once accepted,
     persist that decision so it stops resurfacing (see step 5) — don't
     re-ask about the same album on a later scan.
   - **Various Artists compilations** (standing decision, July 2026):
     filenames are `## - Artist - Title.flac` (multi-disc:
     `<disc>-## - Artist - Title.flac`), regenerated from each file's
     ARTIST/TITLE tags with the usual sanitizer. The scanner still
     expects title-only names, so these albums are recorded as accepted
     exceptions after renaming — a new VA rip (abcde emits
     `NN-Artist-Title.flac`) gets renamed to this format and accepted,
     no need to re-ask.
   - **Quote artifacts** — doubled single quotes (`''Title''`) standing in
     for real punctuation. Check the actual official title (web search)
     before deciding whether real quotes belong there at all — some
     "quoted-looking" titles aren't quoted in the official release.

4. **Multi-disc albums get consolidated into one flat folder with a
   disc-track prefix.** The standard is `<disc>-<track> - Title.flac`
   (disc number unpadded, track zero-padded to 2 digits — e.g.
   `2-05 - Touch (2021 Epilogue).flac`), all discs' files living directly
   in the album directory rather than in separate `CD 1`/`CD 2`/`Disc N`
   subdirectories. `scan_album`/`scan_state.sh` already expect this
   format whenever a file's `DISCTOTAL` tag is `> 1` — a plain
   `## - Title.flac` name is flagged as wrong in that case, and a
   `<disc>-<track>` name is flagged as wrong when `DISCTOTAL` is absent
   or `1`.

   Run `scripts/consolidate_multidisc.sh <album-dir>` to do the
   conversion. It handles two starting layouts on its own: separate `CD
   N`/`Disc N` subdirectories (moves every file up into the album dir,
   renames it, corrects `DISCNUMBER`/`DISCTOTAL` to match which subdir it
   physically came from, moves non-flac files like `folder.jpg` up too —
   disambiguating a same-named collision across discs with a `-<disc>`
   suffix — then removes the emptied subdirs); or an already-flat folder
   that just uses continuous numbering instead of a disc prefix (renames
   in place using each file's own existing `DISCNUMBER`/`TRACKNUMBER`/
   `TITLE` tags). `TRACKNUMBER` itself is left disc-relative (resets each
   disc) — only the filename gets the disc prefix. Title text used in the
   new filename has `/` replaced with `-` (matching the rest of the
   library's convention) and any of `< > : " \ | ? *` replaced with `_`
   (these are invalid in Windows/NTFS filenames AND on the exFAT SAILBOAT
   drive — see the character restriction at the top of this document) —
   always spot-check the result of a batch for stray
   literal quote/colon/etc. characters the sanitizer might have missed if
   the tag text has an unusual shape.

   After consolidating, `scan_state.sh` will still list the removed `CD
   N` subdirectory paths in its state file as harmless orphaned rows
   (their fingerprint just never gets looked up again) — safe to leave,
   or prune with `--list` piped through a filter if you want it tidy.

5. **Persist accepted exceptions with `scan_state.sh --accept`.** For any
   flagged album that turns out to be an intentional exception (simplified
   filename policy, or a structural false positive like multi-disc
   numbering) rather than something to fix:
   ```
   scripts/scan_state.sh "<library-root>" --accept "<album-relpath>"
   ```
   `<album-relpath>` is the path printed after `##ALBUM##` **with the
   leading `./` stripped** (e.g. `Fats Waller/Fats and His Buddies`, not
   `./Fats Waller/...`). The state file keys rows without the prefix, so
   an accept given with `./` is stored but never matched on lookup — the
   album keeps resurfacing and the bogus `./`-prefixed row has to be
   pruned from the state TSV. This records the album's current fingerprint
   as clean, so `scan_state.sh` stops reporting it — until its `.flac`
   contents actually change again, at which point it's re-scanned fresh.
   `scripts/scan_state.sh "<library-root>" --list` shows everything
   currently recorded (clean vs. accepted, and when); `--reset` wipes all
   state for that root if you need to force a full fresh scan.

6. **Verifying facts (correct title/track count/etc.).** When a tag looks
   wrong (truncated, mis-titled, missing a bonus-track disambiguator) and
   you need ground truth, check the official tracklist (Wikipedia album
   page, or the label's own listing) rather than guessing — don't trust a
   single web-search snippet if it looks truncated the same way the bad
   tag is (some tracklist aggregators scraped the same bad metadata).

7. **Re-run `scan_state.sh` after fixing a batch** to confirm the fix
   worked (the album should now come back clean and auto-record itself)
   before moving to the next one.

## Reference: setting tags with metaflac

```sh
# Read one tag
metaflac --show-tag=TITLE "file.flac" | sed -E 's/^[^=]+=//'

# Replace a tag (remove first — metaflac --set-tag appends, doesn't overwrite)
metaflac --remove-tag=TITLE --set-tag="TITLE=Correct Title" "file.flac"

# Full comment dump, to see everything present before deciding what to fix
metaflac --list --block-type=VORBIS_COMMENT "file.flac"
```

Vorbis comment tag names are conventionally case-insensitive on read via
`--show-tag`, but existing files in a library are often inconsistent
about the case they were written with (`Title` vs `TITLE`). Preserve
whatever case convention the rest of that album/artist already uses
rather than introducing a third variant.

## Scripts

All under `scripts/`, all bash (run by path, don't paste their contents
into an interactive zsh shell — see gotcha #1 above).

| Script | Purpose |
|---|---|
| `scan_state.sh <root> [--accept <relpath> \| --reset \| --list]` | Incremental scan (default for repeat use). Skips unchanged clean/accepted albums. |
| `audit.sh <root>` | Full stateless scan of every album, every time. |
| `lib.sh` | Shared `scan_album`/`fingerprint_album` functions — sourced by the two scanners above, not run directly. |
| `rename_to_standard.sh <album-dir>` | Fixes wrong-separator-only filenames (`01. Title`/`01-Title` → `01 - Title`), replacing forbidden characters in the title portion with `_`. Tags untouched. |
| `rename_from_tags.sh <album-dir>` | Regenerates every filename in a dir from that file's own TRACKNUMBER/TITLE tags (`/` → `-`, forbidden chars → `_`). Use after fixing tags on a garbled-filename rip, or to purge forbidden characters from names. |
| `sanitize_dirnames.sh <library-root> [--dry-run]` | Renames artist/album directories containing forbidden characters (`" < > : \ \| ? *` → `_`), depth-first, never overwriting. Renamed albums reappear as "new" in `scan_state.sh`. |
| `fix_tag_whitespace.sh <album-dir>` | Strips leading/trailing/doubled whitespace from TITLE/ALBUM/ARTIST tags. |
| `fix_tracknumber_format.sh <album-dir>` | Splits combined `TRACKNUMBER=N/total` / `DISCNUMBER=N/total` into separate total tags, and zero-pads a plain unpadded `TRACKNUMBER` (`1` → `01`). |
| `consolidate_multidisc.sh <album-dir>` | Merges `CD N`/`Disc N` subdirectories (or an already-flat continuously-numbered folder) into one directory with `<disc>-<track> - Title.flac` filenames; corrects `DISCNUMBER`/`DISCTOTAL` tags to match. |

State files (used only by `scan_state.sh`) live in `state/`, one per
library root, named by a sha1 of that root's absolute path. Safe to
delete individually or wholesale — worst case is just a full re-scan.
