# Signing the release APK

Until a release key exists, every APK this project builds (even `flutter build apk --release`) is signed with the
**debug key** of the machine that built it. That is fine for the owner's own phone and **wrong for a public release**:
the same key must sign every version that is ever published, or nobody can update the app.

`android/app/build.gradle.kts` already handles both cases:

- `android/key.properties` exists: the release build is signed with the key it names.
- `android/key.properties` does not exist: the release build is signed with the debug key, as before (nothing breaks).

`tool/release.sh` refuses to produce an APK for publishing while the file is missing (see the script).

## WARNING: the phone has the debug-signed app

> تحذير: التطبيق المثبّت على هاتف المالك موقَّع بمفتاح debug. أندرويد يرفض تحديثًا موقَّعًا بمفتاح مختلف، فالانتقال
> إلى المفتاح الجديد يعني **حذف التطبيق ثم تثبيته من جديد**، وحذفه يمسح كل بياناته (الأوراد والعلامات والموضع والإعدادات).

So the first install of the release-signed APK on the owner's phone needs this order:

1. In the old app: Settings, «تصدير نسخة احتياطية». Save the file `mushaf-backup-YYYY-MM-DD.json` **outside the app**
   (copy it to the computer or another app's storage) and check that it opens and is not empty.
2. Uninstall the old app (this erases its data on the phone).
3. Install the release-signed APK.
4. In the new app: Settings, «استيراد نسخة احتياطية», pick the file, confirm.

Do not count on Android's own backup to restore the data. Only the app's export file is guaranteed (Constitution IV).

Everyone who installs the public APK later gets the release key from the start, so they never see this problem.
(An advanced alternative exists, Android's APK signature key rotation with `apksigner rotate`, which could avoid the
uninstall; it is not set up or tested in this project.)

## 1. Create the key (once, by the owner)

Keep it **outside the repository**. This command asks for two things you must choose and remember: a password, and the
"distinguished name" fields. The name fields are written into the certificate of every APK, so they become public:
use a name or handle you are happy to show publicly and no private email address.

```bash
mkdir -p ~/.mushaf-signing
keytool -genkeypair -v \
  -keystore ~/.mushaf-signing/mushaf-release.jks \
  -storetype PKCS12 \
  -alias mushaf \
  -keyalg RSA -keysize 4096 \
  -validity 10000
```

`-validity 10000` is about 27 years. With the PKCS12 format the key password is the same as the store password
(keytool ignores a separate one), so use the same value for both in step 2.

## 2. Tell Gradle where it is

Create `android/key.properties` (git-ignored; it holds passwords):

```properties
storeFile=/home/YOUR_USER/.mushaf-signing/mushaf-release.jks
storePassword=THE_PASSWORD
keyAlias=mushaf
keyPassword=THE_PASSWORD
```

Use an absolute `storeFile`. A relative one is read from `android/app/`.

## 3. Build and check

```bash
tool/release.sh
keytool -printcert -jarfile build/release/mushaf-hafiz-v1.0.0.apk      # shows the owner of the certificate, SHA-256
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs build/release/mushaf-hafiz-v1.0.0.apk
```

The certificate's SHA-256 should be the one of the release key and not "Android Debug". Writing that fingerprint in the
GitHub release text lets anyone confirm that two downloads come from the same key.

## 4. Back the key up and keep it secret

- Copy `mushaf-release.jks` **and its password** to at least two places the owner controls (for example a password
  manager and an offline USB stick). If the key is lost, no update can ever be installed over the published app:
  everyone would have to uninstall first.
- Never commit it, never paste its password in an issue or a chat, never attach it to a release. `.gitignore` already
  excludes `android/key.properties`, `*.jks` and `*.keystore`, but `git status` is the last check before every commit.
- Use the same key for the GitHub release, itch.io and APKPure.
