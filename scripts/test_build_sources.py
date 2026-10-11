"""Offline regression tests for immutable source downloads and release recovery."""
import hashlib
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import zipfile

import build_sources as build


class SourceIntegrityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = patch.object(build, 'ROOT', Path(self.temp.name))
        self.root.start()
        self.original = b'%PDF- reviewed fixture'
        self.item = {'id': 'fixture', 'asset': 'assets/sources/test.pdf',
                     'url': 'https://example.org/source.pdf',
                     'sha256': hashlib.sha256(self.original).hexdigest()}
        build.restore_release = False
        build._release_zip = None

    def tearDown(self):
        if build._release_zip:
            build._release_zip.close()
        build._release_zip = None
        build.restore_release = False
        self.root.stop()
        self.temp.cleanup()

    def archive(self, content):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, 'w') as z:
            z.writestr('assets/flutter_assets/' + self.item['asset'], content)
        return zipfile.ZipFile(io.BytesIO(buffer.getvalue()))

    def test_valid_cache_never_downloads(self):
        path = build.ROOT / self.item['asset']
        path.parent.mkdir(parents=True)
        path.write_bytes(self.original)
        with patch.object(build.urllib.request, 'urlopen') as request:
            self.assertEqual(build.materialize(self.item), path)
            request.assert_not_called()

    def test_changed_publisher_bytes_fail_without_explicit_restore(self):
        with patch.object(build.urllib.request, 'urlopen', return_value=io.BytesIO(b'changed')):
            with self.assertRaisesRegex(ValueError, 'source changed'):
                build.materialize(self.item)
        self.assertFalse((build.ROOT / self.item['asset']).exists())

    def test_restore_accepts_only_exact_reviewed_asset(self):
        build.restore_release = True
        build._release_zip = self.archive(self.original)
        with patch.object(build.urllib.request, 'urlopen', return_value=io.BytesIO(b'changed')):
            self.assertEqual(build.materialize(self.item).read_bytes(), self.original)

    def test_mismatched_release_asset_is_rejected(self):
        build.restore_release = True
        build._release_zip = self.archive(b'changed')
        with self.assertRaisesRegex(ValueError, 'release asset mismatch'):
            build.restore_snapshot(self.item)

    def test_mismatched_whole_release_is_rejected(self):
        build.restore_release = True
        with patch.object(build.urllib.request, 'urlopen', return_value=io.BytesIO(b'not-the-pinned-apk')):
            with self.assertRaisesRegex(ValueError, 'archive checksum mismatch'):
                build.restore_snapshot(self.item)


if __name__ == '__main__':
    unittest.main()
