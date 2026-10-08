from pathlib import Path
import re

p=Path('android/app/build.gradle.kts')
text=p.read_text()
text=text.replace('minSdk = flutter.minSdkVersion','minSdk = 23')
text += '\ndependencies {\n    implementation("com.google.mlkit:text-recognition-korean:16.0.1")\n}\n'
p.write_text(text)
p=Path('android/app/src/main/AndroidManifest.xml')
text=p.read_text().replace('<application','<uses-permission android:name="android.permission.INTERNET"/>\n    <application',1)
text=text.replace('android:label="kwrmyanmar"','android:label="KWR Myanmar"')
text=text.replace('<application','<application android:allowBackup="false" android:usesCleartextTraffic="false"',1)
p.write_text(text)
Path('android/gradle.properties').write_text(Path('android/gradle.properties').read_text()+'\nandroid.enableJetifier=true\n')
print('Android: internet, minSdk 23, bundled Korean OCR, backup disabled')
