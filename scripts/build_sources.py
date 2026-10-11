"""Build the pinned offline pack before Flutter builds. No app startup download.

Publisher PDFs stay byte-for-byte originals. SHA-256 mismatch fails the build
rather than silently replacing reviewed source snapshots. pdftotext (Poppler)
provides a per-page search index; the original PDF remains available in the app.
"""
import concurrent.futures
import argparse
import hashlib
import io
import json
import subprocess
import threading
import urllib.request
import zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'assets/source_manifest.json').read_text())
restore_release = False
_release_lock = threading.Lock()
_release_zip = None

def restore_snapshot(item):
    """Recover reviewed bytes from a pinned release, never execute the APK.

    Publishers may regenerate a PDF at the same URL. The whole archive and each
    asset are checked independently; this cannot accept a changed legal edition.
    """
    global _release_zip
    if not restore_release:
        raise ValueError('Reviewed snapshot unavailable; use --restore-pinned-release to recover the exact published bytes.')
    with _release_lock:
        if _release_zip is None:
            url = 'https://github.com/myothuonion-ui/KWRMyanmar/releases/download/v0.2.2/KWRMyanmar-v0.2.2.apk'
            expected = 'c9421d1233db277cdb6fc5b02d0fe8962faf24d4efdb7d1a77927ddfc58f8873'
            with urllib.request.urlopen(url, timeout=180) as response:
                content = response.read(140_000_001)
            if len(content) > 140_000_000 or hashlib.sha256(content).hexdigest() != expected:
                raise ValueError('Pinned release archive checksum mismatch')
            _release_zip = zipfile.ZipFile(io.BytesIO(content))
        content = _release_zip.read('assets/flutter_assets/' + item['asset'])
        if hashlib.sha256(content).hexdigest() != item['sha256']:
            raise ValueError(f"{item['id'] if 'id' in item else 'font'}: pinned release asset mismatch")
    print(f"Recovered reviewed snapshot: {item['asset']}", flush=True)
    return content

def materialize(item):
    path=ROOT/item['asset']
    path.parent.mkdir(parents=True,exist_ok=True)
    if path.exists() and hashlib.sha256(path.read_bytes()).hexdigest()==item['sha256']:
        return path
    try:
        with urllib.request.urlopen(item['url'],timeout=90) as response:
            content=response.read()
    except (OSError, urllib.error.URLError):
        content=restore_snapshot(item)
    digest=hashlib.sha256(content).hexdigest()
    if digest!=item['sha256']:
        if not restore_release:
            raise ValueError(f"{path.name}: source changed ({digest}). Review the new official edition and explicitly update source_manifest.json.")
        content=restore_snapshot(item)
    path.write_bytes(content)
    return path

def index(item):
    source=dict(item)
    if not item['asset']:
        return source
    path=materialize(item)
    if not path.read_bytes().startswith(b'%PDF-'):
        raise ValueError(f'{path.name}: not a PDF')
    result=subprocess.run(['pdftotext','-layout',str(path),'-'],capture_output=True,check=True)
    pages=result.stdout.decode('utf-8').split('\f')
    if not pages[-1].strip(): pages.pop()
    if not pages or len(''.join(pages).strip())<500:
        raise ValueError(f'{path.name}: incomplete text extraction')
    source['pages']=[p.strip() for p in pages]
    # Reject conspicuously broken publisher encoding, found in csmSeq 999.
    if 'ì‡´ì§' in ''.join(pages) or 'ë³´ë' in ''.join(pages):
        raise ValueError(f'{path.name}: unreadable publisher encoding')
    print(f"{item['id']}: {len(pages)} pages",flush=True)
    return source

if __name__=='__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--restore-pinned-release', action='store_true')
    restore_release = parser.parse_args().restore_pinned_release
    expected={Path(s['asset']).name for s in manifest['sources'] if s['asset']}
    extras={p.name for p in (ROOT/'assets/sources').glob('*.pdf')}-expected
    if extras: raise ValueError(f'Unexpected source assets: {extras}')
    materialize(manifest['font'])
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        sources=list(executor.map(index,manifest['sources']))
    (ROOT/'assets/sources.json').write_text(json.dumps(sources,ensure_ascii=False,indent=2)+'\n')
    print('Offline pack:',len(sources),'sources,',sum(len(s['pages']) for s in sources),'pages')
