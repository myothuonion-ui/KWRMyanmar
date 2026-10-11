import base64
from pathlib import Path
import stat
import tempfile
import unittest

from configure_signing import configure
from verify_signing import check_certificate, EXPECTED

class SigningTests(unittest.TestCase):
    def test_missing_credentials_never_generate_a_replacement_key(self):
        with self.assertRaisesRegex(ValueError, 'Missing signing secrets'):
            configure({})

    def test_original_certificate_is_required(self):
        check_certificate(f'Signer #1 certificate SHA-256 digest: {EXPECTED}')
        for output in ['', 'Signer #1 certificate SHA-256 digest: ' + '0' * 64,
                       f'Signer #1 certificate SHA-256 digest: {EXPECTED}\nSigner #2 certificate SHA-256 digest: {EXPECTED}']:
            with self.assertRaises(ValueError):
                check_certificate(output)

    def test_current_v03_preview_is_detected_as_an_incompatible_upgrade(self):
        with self.assertRaisesRegex(ValueError, 'differs from v0.2.2'):
            check_certificate('Signer #1 certificate SHA-256 digest: 84a93b375b733c005fd94ab758e1d910ab8c8eea3250670b931aa29c50c0e0eb')

    def test_temporary_keystore_is_private_and_env_contains_only_its_path(self):
        with tempfile.TemporaryDirectory() as temp:
            env_file = Path(temp, 'env')
            fixture = b'SYNTHETIC_NOT_A_REAL_KEY' * 80
            env = {'RUNNER_TEMP':temp, 'GITHUB_ENV':str(env_file),
                   'KWR_SIGNING_KEYSTORE_B64':base64.b64encode(fixture).decode(),
                   'KWR_SIGNING_STORE_PASSWORD':'test-password',
                   'KWR_SIGNING_KEY_ALIAS':'test-alias', 'KWR_SIGNING_KEY_PASSWORD':'test-password'}
            path = configure(env)
            self.assertEqual(path.read_bytes(), fixture)
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
            self.assertEqual(env_file.read_text(), f'KWR_SIGNING_STORE_FILE={path}\n')
            env['KWR_SIGNING_STORE_PASSWORD'] = 'unsafe\nOTHER_ENV=value'
            with self.assertRaises(ValueError):
                configure(env)

if __name__ == '__main__':
    unittest.main()
