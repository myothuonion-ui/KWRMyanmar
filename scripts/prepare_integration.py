"""Temporarily include the native test bridge in the test-target release APK.

The distributable APK has already been built and copied to dist. Flutter excludes
dev plugins from release builds, so native release instrumentation needs this
SDK plugin classified as a regular dependency in its separate test build.
"""
from pathlib import Path

p=Path('pubspec.yaml')
text=p.read_text()
block='dev_dependencies:\n  integration_test:\n    sdk: flutter\n'
assert block in text, 'Integration dependency layout changed'
text=text.replace(block,'dev_dependencies:\n',1)
text=text.replace('dependencies:\n','dependencies:\n  integration_test:\n    sdk: flutter\n',1)
p.write_text(text)
print('Native integration bridge enabled for the separate release test target.')
