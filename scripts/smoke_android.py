"""Launch the exact release APK and capture each tab on a fresh emulator."""
from pathlib import Path
import re
import subprocess
import time

def adb(*args, binary=False):
    return subprocess.check_output(['adb',*args],text=not binary)

output=Path('dist/screenshots')
output.mkdir(parents=True,exist_ok=True)
adb('install','-r','dist/KWRMyanmar-v0.1.0.apk')
adb('shell','pm','clear','com.myothuonion.kwrmyanmar')
adb('logcat','-c')
adb('shell','am','start','-W','-n','com.myothuonion.kwrmyanmar/.MainActivity')
time.sleep(8)
size=adb('shell','wm','size')
width,height=map(int,re.findall(r'(\d+)x(\d+)',size)[-1])
for i,name in enumerate(['cards','chat','visa','pay','files']):
    adb('shell','input','tap',str(round(width*(i+.5)/5)),str(height-100))
    time.sleep(2)
    (output/f'{name}.png').write_bytes(adb('exec-out','screencap','-p',binary=True))
adb('shell','input','tap',str(width-60),'100')
time.sleep(2)
(output/'settings.png').write_bytes(adb('exec-out','screencap','-p',binary=True))
logs=adb('logcat','-d')
(output/'runtime.log').write_text(logs)
if 'FATAL EXCEPTION' in logs or '[ERROR:flutter/runtime/dart_vm_initializer' in logs:
    raise SystemExit('Runtime exception detected. Inspect screenshot/runtime artifacts.')
if not adb('shell','pidof','com.myothuonion.kwrmyanmar').strip():
    raise SystemExit('Release app did not stay running.')
print('Release APK launched and six screens captured without runtime exceptions.')
