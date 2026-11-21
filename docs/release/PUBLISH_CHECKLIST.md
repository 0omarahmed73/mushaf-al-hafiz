# Publish checklist (v1.0.0)

The order matters: each step needs the one before it. The owner decided on 2026-11-21 to release the app publicly and
non-commercially on GitHub (repository and release), itch.io and APKPure (Constitution 1.3.0, `docs/research/licenses.md`).
An agent cannot sign in to an account for the owner: every step marked **Owner** is the owner's own hands.

Stop and do not publish if any of these is true: the APK is signed with the debug key; `flutter analyze` or `flutter test`
fails on the commit being released; `aapt2 dump permissions` shows `INTERNET`; the About screen still calls the app
"personal"; any file of `data-raw/`, `assets/mushaf/`, `assets/ayah/` or `assets/fonts/qpc-v2/` shows up in `git status`.

## Step 0. Decisions (Owner answers; questions ready in Egyptian Arabic at the end of AUDIT.md)

| Decision | Why it blocks | Default if the owner has no preference |
|---|---|---|
| The email for public commits | The current Gmail address is in all 250 commits | The GitHub no-reply address (`<id>+<username>@users.noreply.github.com`, shown in GitHub Settings, Emails) |
| History: new single commit, or rewrite the 250 | Same | A new history from the cleaned tree |
| Licence of the app's own code | A public repository without a `LICENSE` file is "all rights reserved" | MIT, with the name the owner wants to show |
| Repository name and owner account | The release URL, the store texts and the README use it | `mushaf-al-hafiz`, public |
| The owner's name, links and the dedication staying in About | They become public | Keep as they are, if the owner confirms |
| Files to remove from the public tree | `AUDIT.md` sections 5 and 6 | Remove `docs/speckit-prompts.md` and `docs/superpowers/`; keep `specs/` |
| The khatm dua's source (paragraphs 3 to 11) | A named source is asked for by Constitution III | Keep the record "customary wording, source not named" |
| A public contact address for the stores | itch.io and APKPure may show it | The repository's Issues page, plus an address only if a form insists |

## Step 1. Make the app match the public statement (coordinator; small feature edits)

1. Change the two "personal" strings in `lib/settings/about_screen.dart` (and the tests that assert them), see `AUDIT.md` §7.
2. Optional but recommended: add a "open-source licences" entry (`showLicensePage`), see `AUDIT.md` §8.
3. Decide what v1.0.0 contains. The release notes list features 001 to 005 only. If features 006 (bookmark button), 007 (al-Kahf
   day) or 009 (icon and splash) land before the build, finish them properly and add them to
   `docs/release/RELEASE_NOTES_v1.0.0.md` and `STORE_LISTINGS.md`; if they are not finished, build from a commit that does not
   contain them. Build from a clean commit, never from a working tree with unfinished edits.
   **Update 2026-11-21:** features 006 to 011 (bookmark button, al-Kahf day, first-run tips, icon and splash, smooth motion,
   search) are now in the app, and landscape shows the bars by default; `RELEASE_NOTES_v1.0.0.md` and `STORE_LISTINGS.md`
   were updated on that day to list them. v1.0.0 contains features 001 to 011. The new Arabic sentences in both files are
   proposals until the owner confirms them (Constitution VI).
4. `pubspec.yaml` `version:` is the one the file name takes (`1.0.0+1`). Raise the build number (`+2`, ...) for any later upload.

## Step 2. Clean the public tree (coordinator)

1. Replace the phone serial and the absolute paths (`AUDIT.md` §2 and §4); remove the files the owner chose in Step 0.
2. Add `LICENSE` with the owner's choice; update the last bullet of the README ("will be added") and put the repository URL
   in the README and in `STORE_LISTINGS.md` (`<REPO_URL>`, `<SUPPORT_URL>`).
3. Re-run the audit commands (top of `AUDIT.md`); `git ls-files | grep -E 'data-raw|assets/(mushaf|ayah)|qpc-v2'` must print nothing.
4. `flutter analyze` and the whole `flutter test` pass on the final commit.

Note (2026-11-21): `tool/make_public_tree.sh` does items 1 and 3 on a copy (never on this repository) and makes its single commit; see the top of the script.

## Step 3. Create the signing key (Owner, at the terminal)

Follow `docs/release/SIGNING.md`: `keytool` command, `android/key.properties`, and **back the key up in two places**.
Needs from the owner: a password they will not lose, and a name or handle they are happy to show in the certificate.
Everything published later (GitHub, itch.io, APKPure, every update) must use this same key.

## Step 4. Build the APK (coordinator or owner)

```bash
tool/release.sh
```

It refuses to build without `android/key.properties`, builds, copies the APK to `build/release/mushaf-hafiz-v1.0.0.apk` and
prints size and sha256. Then:

```bash
~/Android/Sdk/build-tools/<version>/aapt2 dump permissions build/release/mushaf-hafiz-v1.0.0.apk   # no INTERNET
~/Android/Sdk/build-tools/<version>/apksigner verify --print-certs build/release/mushaf-hafiz-v1.0.0.apk
```

Fill the `<SIZE>`, `<SHA256>` and `<CERT_SHA256>` placeholders in `RELEASE_NOTES_v1.0.0.md`, and the size in
`STORE_LISTINGS.md` (it says "about 180 MB"; correct it if the real size differs by more than a few MB).

## Step 5. Back up the phone, install the release build and test it (Owner)

The app on the owner's phone is signed with the debug key, and Android will not update it with the new key.

1. Export a backup in the app (Settings, «تصدير نسخة احتياطية») and copy the file off the phone.
2. Uninstall the app (this erases its data).
3. Install the release APK from Step 4, then import the backup.
4. Check at least: the app opens straight on a Mushaf page; airplane mode changes nothing; a reminder arrives with the screen
   locked; export and import of a backup; the ayah menu (tafsir, translation, meanings); the About screen and its credits; the
   app's permission page shows no Internet. Record the results in the feature specs' phone checklists. Anything that fails
   stops the release.

## Step 6. GitHub (Owner signs in; the coordinator can run the commands once the owner has logged in)

1. Owner: create the repository (empty: no README, no licence, no .gitignore from the site). In GitHub Settings, Emails: turn on
   "Keep my email addresses private" and "Block command line pushes that expose my email".
2. Set the commit identity on the copy being published (Step 0): `git config user.name "<name>"` and
   `git config user.email "<no-reply address>"`.
3. Make the public history (Step 0, option A or B) in a **new folder**, check it with the audit commands, then
   `git remote add origin <url>` and `git push -u origin main`.
4. Tag and release: `git tag v1.0.0 && git push origin v1.0.0`, then (Owner runs `gh auth login` themselves, never shares a token)

   ```bash
   gh release create v1.0.0 build/release/mushaf-hafiz-v1.0.0.apk build/release/mushaf-hafiz-v1.0.0.apk.sha256 \
     --title "مصحف الحافظ 1.0.0" --notes-file docs/release/RELEASE_NOTES_v1.0.0.md
   ```

   or the same through the web page "Releases, Draft a new release".
5. Open the release page from a private window and download the APK once; its sha256 must equal the one in the notes.

## Step 7. itch.io (Owner signs in)

Create the account, then the project, with the fields and texts in `STORE_LISTINGS.md` (itch.io section). Upload the **same file**
as the GitHub release, tick Android, keep it Draft, view it as a visitor, then make it Public. Needs: the account, the project
URL slug, screenshots (list in `STORE_LISTINGS.md`), a cover image.

## Step 8. APKPure (Owner signs in)

Create the developer account and submit the same APK with the APKPure section of `STORE_LISTINGS.md`. Needs: the account,
the contact address for the page, screenshots. A review may take days; the page is not live until it passes.

## Step 9. After publishing

1. Install once from each store on a clean phone or profile and check the sha256 matches.
2. Put the three links in the README (a one-line "Download" section) and in the GitHub repository description.
3. Keep `android/key.properties`, the keystore and its password safe and outside the repository (`SIGNING.md` §4).
4. If a rights holder objects (Constitution 1.3.0): remove the resource (or the app) as the constitution says, release a new
   version signed with the same key, withdraw the old files from the stores, and record it in `docs/research/licenses.md`.

## What the owner has to bring (summary)

- Their own sign-ins: GitHub, itch.io, APKPure (the agent never enters credentials).
- The email for public commits (and an optional public contact address for the stores).
- The code licence choice and the name for its copyright line.
- The repository name and visibility.
- The signing key password and two places to back the key up.
- Their phone, for Step 5, and the screenshots.
