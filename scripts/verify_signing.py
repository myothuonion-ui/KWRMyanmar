"""Fail closed before publication if APK signing cannot preserve v0.2.2 upgrades."""
import os
from pathlib import Path
import re
import subprocess

EXPECTED = 'a7b902bab5bc95a38a6c3231dbe71aa01304c0b021f5f5ab4f1f4c69f6013eee'

def check_certificate(output):
    digests = re.findall(r'Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]{64})', output)
    if len(digests) != 1 or digests[0].lower() != EXPECTED:
        raise ValueError('Signing certificate differs from v0.2.2. Do not publish an in-place update or uninstall the old app.')

def main():
    sdk = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    if not sdk:
        raise SystemExit('Android SDK is needed for signature verification')
    tools = sorted(Path(sdk, 'build-tools').glob('*/apksigner'))
    if not tools:
        raise SystemExit('apksigner is unavailable')
    apk = next(Path('dist').glob('KWRMyanmar-v*.apk'))
    # v1 is needed for the declared Android 6.0 minimum; verify it explicitly.
    result = subprocess.run([str(tools[-1]), 'verify', '--print-certs',
                             '--min-sdk-version', '23', str(apk)],
                            capture_output=True, text=True, timeout=30)
    if result.returncode:
        raise SystemExit('APK signature verification failed for the supported Android minimum')
    try:
        check_certificate(result.stdout)
    except ValueError as error:
        raise SystemExit(str(error)) from None
    print('Verified signature and existing v0.2.2 upgrade certificate.')

if __name__ == '__main__':
    main()
