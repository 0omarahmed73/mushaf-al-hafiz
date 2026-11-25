# Google Play: publishing مصحف الحافظ

Prepared 2026-11-25 under constitution 2.1.0. Play's rules were read that day from Google's own help pages (links at the
end); they change, so check the Play Console when you upload. The Arabic texts are proposals until the owner confirms them.

## Who does what

| Step | Who | Notes |
|---|---|---|
| Sign in to the Play Console, accept terms, verify identity | Owner | Personal account (already exists) |
| Create the app «مصحف الحافظ», free, app (not game) | Owner | Default language Arabic |
| Build the `.aab` | Claude | `flutter build appbundle --release`, signed with the upload key (the existing release key) |
| Store texts, privacy policy, Data safety answers, rating answers | Claude prepared, owner pastes | Sections below |
| Privacy policy URL | Owner says «ارفع», Claude pushes `PRIVACY.md` to the public repo | The URL must work before review |
| Screenshots | Owner (on the phone) | List in STORE_LISTINGS.md "Screenshots to take" |
| Upload the `.aab` to a closed test, add testers | Owner | Play App Signing: choose "Let Google create and manage the app signing key" |
| 12 testers opted in for 14 days in a row | Owner and his testers | Required for personal accounts created after 13 Nov 2023 |
| Apply for production access, then release | Owner | Play asks questions about the test |

## The owner's account

Personal account created on 2026-11-24 (the owner's words on 2026-11-25: «انا لسة عامل الاكك امبارح»), so the closed test
rule applies: at least 12 testers opted in continuously for 14 days before production access can be requested. The
earliest date to apply is 14 days after the twelfth tester has opted in.

## Facts the forms need

| Field | Answer |
|---|---|
| App name | مصحف الحافظ |
| Package | `app.hafiz.mushaf` |
| Category | Books & Reference |
| Free or paid | Free. No in-app purchases |
| Ads | No |
| Target audience | 13 and over is the simplest choice (choosing children brings the Families policy). Owner's decision |
| Contact email | An address the owner is happy to make public (required by Play) |
| Website | https://github.com/0omarahmed73/mushaf-al-hafiz |
| Privacy policy URL | https://github.com/0omarahmed73/mushaf-al-hafiz/blob/main/PRIVACY.md (after the push) |
| Target API level | 36 (Play requires 36 for new apps from 31 Aug 2026: met) |
| App signing | Google's key (owner's choice). The Play app and the GitHub APK cannot update each other |

## Data safety form

- Does the app collect or share any of the required user data types? **No.**
- Is all data encrypted in transit? Not applicable (nothing is sent).
- Data deletion: data lives on the phone only and is removed with the app.

## Content rating (IARC questionnaire)

Category: Reference, news or educational. Violence, sexuality, language, controlled substances, gambling: none.
User interaction or user-generated content shared with others: none. Shares location: no. Digital purchases: no.

## Permissions Play will show

`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` (reminders), plus `VIBRATE`, `WAKE_LOCK`, the foreground-service ones and
`ACCESS_NETWORK_STATE` added by libraries. No Internet, no location, no exact alarms (feature 014, if built, will need the
exact-alarm declaration later).

## Store listing texts

Short description (80 characters at most):

```
مصحف المدينة النبوية بلا إنترنت، مع أوراد وتذكيرات. بلا إعلانات ولا تتبّع.
```

Full description: the APKPure Arabic text in STORE_LISTINGS.md, with one line added under «الورد» for feature 013:

```
• علامة على الآية مع ملاحظة، وتظليل خفيف للآيات التي عليها علامة
```

## Size

Play limits the base module to 200 MB compressed download. Measured on 2026-11-25 (commit 8782c7b, version 1.0.0+1): the
`.aab` is 178.2 MB, of which 31.7 MB are debug symbols Play never sends to phones. What one phone downloads, from the
bundle's compressed sizes: assets 108.6 MB + its own processor's native code about 9.2 MB + code and resources about 1 MB,
so about 119 MB: under the limit with no asset pack. Play's own number appears in the Console after the upload.
Privacy policy pushed to the public repository on 2026-11-25 (commit 8318dea) after the owner's «ارفع».

## Sources

- Testing for new personal accounts: https://support.google.com/googleplay/android-developer/answer/14151465
- Target API level: https://support.google.com/googleplay/android-developer/answer/11926878
- Size limits: https://support.google.com/googleplay/android-developer/answer/9859372

## Log

- 2026-11-25 22:29: the owner sent the first closed-test release (1.0.0, versionCode 1) and the store listing for review
  ("Changes in review" on the Publishing overview). Testers come from the email list «Quran App Testers». Advertising ID
  declared "No" (checked: the release has no `AD_ID` permission). Store images made from the app's icon drawing and from
  six phone screenshots the owner took, padded to 9:16 (~/mushaf-play, outside the repository).
- 2026-11-25: version 1.0.1 (versionCode 2) built from commit 50f0f11 plus the version bump. It fixes the Mushaf lines cut at the
  screen edge on phones with a larger system font (two testers, one a Samsung A52). Bundle:
  ~/mushaf-play/mushaf-hafiz-1.0.1.aab. The same two testers saw stutter while turning pages; the owner's phone
  does not. Not measured on their phones; ask them after the update.
