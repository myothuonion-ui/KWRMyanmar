"""Load an owner-provided keystore from GitHub Secrets, never from public cache."""
import base64
import os
from pathlib import Path
import tempfile

REQUIRED = ('KWR_SIGNING_KEYSTORE_B64', 'KWR_SIGNING_STORE_PASSWORD',
            'KWR_SIGNING_KEY_ALIAS', 'KWR_SIGNING_KEY_PASSWORD')

def configure(env):
    if any(not env.get(k) for k in REQUIRED):
        raise ValueError('Missing signing secrets; use the existing v0.2.2 key. See docs/SIGNING.md.')
    if any('\n' in env[k] or '\r' in env[k] for k in REQUIRED[1:]):
        raise ValueError('Signing credentials must be single-line values')
    try:
        content = base64.b64decode(env[REQUIRED[0]], validate=True)
    except ValueError:
        raise ValueError('Invalid base64 signing keystore') from None
    if not 1024 <= len(content) <= 131072:
        raise ValueError('Unexpected signing keystore size')
    with tempfile.NamedTemporaryFile(dir=env['RUNNER_TEMP'], suffix='.keystore', delete=False) as output:
        output.write(content)
        path = Path(output.name)
    with open(env['GITHUB_ENV'], 'a') as output:
        output.write(f'KWR_SIGNING_STORE_FILE={path}\n')
    return path

if __name__ == '__main__':
    try:
        configure(os.environ)
    except (ValueError, KeyError) as error:
        raise SystemExit(str(error)) from None
    print('Owner-provided upgrade signing key loaded; credentials are not printed.')
