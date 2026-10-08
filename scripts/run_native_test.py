"""Preserve native diagnostics even when Android instrumentation fails."""
from pathlib import Path
import subprocess
import sys

target = str(Path('integration_test/app_test.dart').resolve())
result = subprocess.run(['timeout', '15m', './android/gradlew', '-p', 'android',
                         'app:connectedReleaseAndroidTest', f'-Ptarget={target}'])
logs = subprocess.run(['adb', 'logcat', '-d'], capture_output=True, text=True).stdout
Path('dist').mkdir(exist_ok=True)
Path('dist/native-integration.log').write_text(logs)
for line in logs.splitlines():
    if 'flutter' in line.lower() or 'FATAL EXCEPTION' in line or 'NATIVE_' in line:
        print(line)
sys.exit(result.returncode)
