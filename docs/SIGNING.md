# Upgrade signing blocker and proposed fix

The tested v0.3.0 APK has a different signing certificate from the published
v0.2.2 APK. It can be installed on a device without the old app, but it cannot
replace v0.2.2 in place. Do not uninstall the old app to force an update: its
encrypted local files and secure-storage keys may be lost.

The intended `~/.android/debug.keystore` cache was missing, and the successful
workflow reported that the path did not exist, so no signing cache was saved.
The previous private signing key was not supplied in this workspace. A public
certificate or APK cannot substitute for the private keystore.

## Proposed owner setup

This draft changes publishing to require an explicit existing keystore and its
credentials in GitHub Actions Secrets, then verifies the resulting certificate
before publication. Do not merge until the matching old key has been located.
Never commit a private keystore or paste its passwords into an issue/chat.

Repository Settings → Secrets and variables → Actions:

- `KWR_SIGNING_KEYSTORE_B64`: single-line base64 of the existing keystore.
- `KWR_SIGNING_STORE_PASSWORD`: that keystore's password.
- `KWR_SIGNING_KEY_ALIAS`: the existing signing alias.
- `KWR_SIGNING_KEY_PASSWORD`: that alias's password.

Known public certificate fingerprints:

| Release | SHA-256 |
| --- | --- |
| v0.2.2 (required for existing upgrades) | a7b902bab5bc95a38a6c3231dbe71aa01304c0b021f5f5ab4f1f4c69f6013eee |
| v0.3.0 current preview | 84a93b375b733c005fd94ab758e1d910ab8c8eea3250670b931aa29c50c0e0eb |

The draft enables v1/v2 signing and verifies the declared Android 6 minimum.
The current previews lack a v1 JAR signature and were exercised on Android API
35; Android 6 installation has not been validated.

If the matching private key cannot be recovered, decide explicitly on a separate
application ID and a data migration route. That must preserve access to the old
app; silent signer replacement or instructions to clear its data are unsuitable.

Checks completed for this draft: Python signing guard/configuration tests and
inspection against the two published certificate fingerprints. A real signed
upgrade build is still blocked on the owner-provided matching keystore.
