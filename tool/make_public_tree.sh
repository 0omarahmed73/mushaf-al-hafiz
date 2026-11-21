#!/usr/bin/env bash
# Make the PUBLIC copy of this repository: a new folder with a cleaned tree and ONE commit of fresh history.
# (docs/release/PUBLISH_CHECKLIST.md Steps 2 and 6, docs/release/AUDIT.md option A.)
#
# Usage:
#   PUBLIC_GIT_NAME='<name>' PUBLIC_GIT_EMAIL='<id>+<username>@users.noreply.github.com' \
#     tool/make_public_tree.sh [DESTINATION]
#
#   DESTINATION defaults to ../mushaf-al-hafiz-public (next to this repository). It must not exist, or be empty.
#
# What it does, in order:
#   1. Refuses to run: without PUBLIC_GIT_NAME / PUBLIC_GIT_EMAIL; with an email that is not a GitHub no-reply
#      address; with uncommitted changes to tracked files; into a destination that is not empty, that is inside
#      this repository, or that the shell is currently standing in.
#   2. Copies ONLY the tracked files of the current commit (`git archive HEAD`), so ignored and untracked files
#      (the Quran data and fonts, keys, builds) never travel. The local history is not copied and not touched.
#   3. Removes the paths in REMOVE_PATHS (internal notes and tooling the owner chose not to publish).
#   4. Applies the text replacements listed under "Replacements" below (phone serial, absolute local paths).
#   5. Audits the copy and FAILS if anything is found: a personal email of the local history, the phone serial,
#      a /home/<user> path, a forbidden file (generated Quran assets, keys, APKs, .env), a removed path still
#      there, or a missing README.md / LICENSE / specs/ / .specify/.
#   6. `git init -b main` in the copy, sets user.name and user.email in THAT repository's local config only,
#      makes one commit, checks the commit's identity, and prints the file count and the commit id.
#
# It never adds a remote and never pushes: the owner does that by hand after looking at the result.
# It never changes this repository or any global git configuration.
set -euo pipefail

# ----- Settings ----------------------------------------------------------------------------------------------

# Paths removed from the public copy (owner's decisions of 2026-11-21: the internal notes, and AUDIT.md which quotes the masked personal email). specs/ and .specify/ stay.
REMOVE_PATHS=(
  "docs/release/AUDIT.md"
  "docs/speckit-prompts.md"
  "docs/superpowers"
  ".claude"
)

# Replacements (AUDIT.md sections 2 and 4), applied to every text file of the copy:
#   a. the phone serial (a Samsung serial: R5C followed by 8 capitals or digits)   ->  <phone>
#   b. the absolute path of this repository on the owner's machine                 ->  <repo-root>
#   c. any other mention of the owner's home folder                                 ->  ~
# The serial is matched by its shape and the paths are read from this machine at run time, so that this script,
# which is itself published, holds neither of them.
SERIAL_REGEX='R5C[A-Z0-9]{8}'
SERIAL_PLACEHOLDER='<phone>'
REPO_PLACEHOLDER='<repo-root>'
HOME_PLACEHOLDER='~'

# File names that must never be in the copy (extended regular expression on the path relative to the copy).
FORBIDDEN_PATHS_REGEX='(^|/)data-raw(/|$)|(^|/)assets/(mushaf|ayah)(/|$)|(^|/)assets/fonts/qpc-v2(/|$)|(^|/)key\.properties$|\.(jks|keystore|apk|aab)$|(^|/)\.env(\.[^/]*)?$'

# /home/<something> is a leak unless it is the placeholder that docs/release/SIGNING.md uses on purpose.
HOME_PATH_REGEX='/home/[A-Za-z0-9_][A-Za-z0-9_.-]*'
HOME_PATH_ALLOWED='/home/YOUR_USER'

COMMIT_MESSAGE='Initial public release'

# ----- Helpers -----------------------------------------------------------------------------------------------

die() { echo "make_public_tree.sh: $*" >&2; exit 1; }

# ----- 1. Checks before anything is written ------------------------------------------------------------------

src="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
git -C "$src" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$src is not a git repository"

: "${PUBLIC_GIT_NAME:?make_public_tree.sh: set PUBLIC_GIT_NAME (the name shown on the public commit)}"
: "${PUBLIC_GIT_EMAIL:?make_public_tree.sh: set PUBLIC_GIT_EMAIL (your GitHub no-reply address)}"
if ! [[ "$PUBLIC_GIT_EMAIL" =~ ^[A-Za-z0-9._+-]+@users\.noreply\.github\.com$ ]]; then
  die "PUBLIC_GIT_EMAIL must be a GitHub no-reply address (<id>+<username>@users.noreply.github.com)"
fi

if [ -n "$(git -C "$src" status --porcelain --untracked-files=no)" ]; then
  die "the working tree has uncommitted changes to tracked files; commit them first (only committed files are published)"
fi

dest_arg="${1:-$src/../mushaf-al-hafiz-public}"
if [ -e "$dest_arg" ]; then
  [ -d "$dest_arg" ] || die "destination exists and is not a folder: $dest_arg"
  [ -z "$(ls -A "$dest_arg")" ] || die "destination exists and is not empty: $dest_arg"
fi
mkdir -p "$dest_arg"
dest="$(cd "$dest_arg" && pwd -P)"

here="$(pwd -P)"
case "$here/" in
  "$dest/"*) rmdir "$dest" 2>/dev/null || true; die "do not run this from inside the destination ($dest)" ;;
esac
case "$dest/" in
  "$src/"*) rmdir "$dest" 2>/dev/null || true; die "the destination must be outside this repository ($src)" ;;
esac

# The emails of the local history are read here only to search for them in the copy; they are never printed.
mapfile -t private_emails < <(
  git -C "$src" log --all --format='%ae%n%ce' | sort -u | grep -v -E '@users\.noreply\.github\.com$|^$' || true
)

# ----- 2. Copy the tracked files of the current commit -------------------------------------------------------

source_commit="$(git -C "$src" rev-parse --short HEAD)"
echo "Source commit: $source_commit ($(git -C "$src" ls-files | wc -l | tr -d ' ') tracked files)"
git -C "$src" archive --format=tar HEAD | tar -x -C "$dest"

# ----- 3. Remove what is not published -----------------------------------------------------------------------

for path in "${REMOVE_PATHS[@]}"; do
  rm -rf -- "${dest:?}/$path"
  echo "Removed: $path"
done

# ----- 4. Replacements ---------------------------------------------------------------------------------------

home_dir="$(cd "$HOME" && pwd -P)"
export MPT_SERIAL="$SERIAL_REGEX" MPT_SERIAL_TO="$SERIAL_PLACEHOLDER" \
       MPT_REPO="$src" MPT_REPO_TO="$REPO_PLACEHOLDER" \
       MPT_HOME="$home_dir" MPT_HOME_TO="$HOME_PLACEHOLDER"

# Text files only (grep -I skips binaries); the patterns narrow the list to files that need an edit.
mapfile -d '' -t to_edit < <(
  grep -rIlZ -E -e "$SERIAL_REGEX" -e "$HOME_PATH_REGEX" "$dest" || true
)
for file in "${to_edit[@]}"; do
  perl -i -pe '
    s/(?<![A-Za-z0-9])$ENV{MPT_SERIAL}(?![A-Za-z0-9])/$ENV{MPT_SERIAL_TO}/g;
    s/\Q$ENV{MPT_REPO}\E/$ENV{MPT_REPO_TO}/g;
    s/\Q$ENV{MPT_HOME}\E(?![A-Za-z0-9_.-])/$ENV{MPT_HOME_TO}/g;
  ' "$file"
done
echo "Replacements applied to ${#to_edit[@]} file(s) (serial -> $SERIAL_PLACEHOLDER, repository path -> $REPO_PLACEHOLDER, home -> $HOME_PLACEHOLDER)"

# ----- 5. Audit the copy -------------------------------------------------------------------------------------

problems=0
report() { echo "AUDIT FAILED: $1" >&2; problems=$((problems + 1)); }

# 5a. Personal emails of the local history (file names only are shown, never the address).
for email in "${private_emails[@]}"; do
  if hits="$(grep -rIlF -e "$email" "$dest")"; then
    report "a personal email of the local history is in: $(echo "$hits" | sed "s#^$dest/##" | tr '\n' ' ')"
  fi
done

# 5b. Phone serial.
if hits="$(grep -rIlE -e "$SERIAL_REGEX" "$dest")"; then
  report "the phone serial is in: $(echo "$hits" | sed "s#^$dest/##" | tr '\n' ' ')"
fi

# 5c. Absolute home paths (the documented placeholder is allowed).
if hits="$(grep -rInoE -e "$HOME_PATH_REGEX" "$dest" | grep -v -F -e "$HOME_PATH_ALLOWED")"; then
  report "absolute local paths: $(echo "$hits" | sed "s#^$dest/##" | tr '\n' ' ')"
fi

# 5d. Forbidden files (generated Quran assets, signing keys, builds, environment files).
if hits="$(cd "$dest" && find . -mindepth 1 -printf '%P\n' | grep -E -e "$FORBIDDEN_PATHS_REGEX")"; then
  report "forbidden files: $(echo "$hits" | tr '\n' ' ')"
fi

# 5e. Removed paths are gone; required files and folders are there.
for path in "${REMOVE_PATHS[@]}"; do
  [ ! -e "$dest/$path" ] || report "$path should have been removed"
done
for path in README.md LICENSE pubspec.yaml; do
  [ -s "$dest/$path" ] || report "$path is missing or empty"
done
for path in specs .specify lib test tool; do
  [ -d "$dest/$path" ] || report "the folder $path/ is missing"
done

if [ "$problems" -gt 0 ]; then
  echo "make_public_tree.sh: $problems audit problem(s). Nothing was committed." >&2
  echo "Fix the source (or extend the replacements in this script), delete $dest and run again." >&2
  exit 1
fi
echo "Audit passed: no personal email, serial, local path or forbidden file in the copy."

# ----- 6. One commit, with the public identity, in the new repository only -----------------------------------

# Identity variables of the calling shell would override the local config; drop them for this script.
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_DIR GIT_WORK_TREE

git -C "$dest" init --quiet -b main
git -C "$dest" config --local user.name "$PUBLIC_GIT_NAME"
git -C "$dest" config --local user.email "$PUBLIC_GIT_EMAIL"
git -C "$dest" config --local commit.gpgsign false   # a signature would carry the key's own identity
git -C "$dest" add --all
git -C "$dest" commit --quiet --no-verify -m "$COMMIT_MESSAGE"

# The commit must carry the public identity and nothing else.
identity="$(git -C "$dest" log --format='%ae %ce')"
[ "$identity" = "$PUBLIC_GIT_EMAIL $PUBLIC_GIT_EMAIL" ] || die "the commit does not carry the public email; do not publish $dest"
[ "$(git -C "$dest" rev-list --count HEAD)" = "1" ] || die "expected exactly one commit in $dest"
for email in "${private_emails[@]}"; do
  if git -C "$dest" log --format=fuller | grep -qF -e "$email"; then
    die "a personal email is in the commit of $dest; do not publish it"
  fi
done
[ -z "$(git -C "$dest" remote)" ] || die "the new repository has a remote; it should have none"

echo
echo "Public tree: $dest"
echo "Files:       $(git -C "$dest" ls-files | wc -l | tr -d ' ')"
echo "Commit:      $(git -C "$dest" rev-parse HEAD) ($(git -C "$dest" log -1 --format='%an <%ae>'))"
echo "No remote was added and nothing was pushed. Next: PUBLISH_CHECKLIST.md Step 6."
