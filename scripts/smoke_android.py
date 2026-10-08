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
density=int(re.findall(r'density:\s*(\d+)',adb('shell','wm','density'))[-1])/160

def assert_foreground():
    activities=adb('shell','dumpsys','activity','activities')
    resumed=[line for line in activities.splitlines() if 'mResumedActivity' in line or 'topResumedActivity' in line]
    if not any('com.myothuonion.kwrmyanmar' in line for line in resumed):
        raise SystemExit('App left the foreground: '+repr(resumed))

assert_foreground()
for i,name in enumerate(['cards','chat','visa','pay','files']):
    adb('shell','input','tap',str(round(width*(i+.5)/5)),str(round(height-88*density)))
    time.sleep(2)
    assert_foreground()
    (output/f'{name}.png').write_bytes(adb('exec-out','screencap','-p',binary=True))
adb('shell','input','tap',str(round(width-24*density)),str(round(52*density)))
time.sleep(2)
assert_foreground()
(output/'settings.png').write_bytes(adb('exec-out','screencap','-p',binary=True))
logs=adb('logcat','-d')
(output/'runtime.log').write_text(logs)
if 'FATAL EXCEPTION' in logs or '[ERROR:flutter/runtime/dart_vm_initializer' in logs:
    raise SystemExit('Runtime exception detected. Inspect screenshot/runtime artifacts.')
if not adb('shell','pidof','com.myothuonion.kwrmyanmar').strip():
    raise SystemExit('Release app did not stay running.')
print('Release APK launched and six screens captured without runtime exceptions.')
