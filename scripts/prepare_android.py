from pathlib import Path

p=Path('android/app/build.gradle.kts')
text=p.read_text()
text=text.replace('minSdk = flutter.minSdkVersion','minSdk = 23')
assert 'release {' in text, 'Flutter Android template changed'
text=text.replace('release {','release {\n            proguardFiles("proguard-rules.pro")',1)
text=text.replace('defaultConfig {','defaultConfig {\n        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"\n        testProguardFiles("proguard-test-rules.pro")',1)
text=text.replace('android {','android {\n    testBuildType = "release"',1)
text += '''
dependencies {
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
    androidTestImplementation("androidx.test:runner:1.3.0")
    androidTestImplementation("androidx.test:rules:1.2.0")
    androidTestImplementation("junit:junit:4.12")
}
'''
p.write_text(text)
Path('android/app/proguard-rules.pro').write_text('''# The Flutter OCR bridge references optional scripts. This app only calls Korean.
# Korean/Latin dependencies remain bundled and are exercised in release integration tests.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
# ML Kit's component factories are discovered by reflection. AGP 9's R8
# can otherwise remove them and return null when creating the OCR recognizer.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar { public <init>(); }
# Native instrumentation references this plugin from the separate test APK.
-keep class dev.flutter.plugins.integration_test.** { *; }
# The test APK manifest names a runner supplied by the test-target app runtime.
-keep class androidx.test.** { *; }
-keep class org.junit.** { *; }
-keep class junit.** { *; }
-keep class org.hamcrest.** { *; }
-keepattributes *Annotation*
''')
Path('android/app/proguard-test-rules.pro').write_text('''-keep class com.myothuonion.kwrmyanmar.MainActivityTest { *; }
-keep class androidx.test.** { *; }
-keep class org.junit.** { *; }
-keep class junit.** { *; }
-keep class org.hamcrest.** { *; }
-keep class dev.flutter.plugins.integration_test.** { *; }
-keepattributes *Annotation*
''')
test=Path('android/app/src/androidTest/java/com/myothuonion/kwrmyanmar/MainActivityTest.java')
test.parent.mkdir(parents=True,exist_ok=True)
test.write_text('''package com.myothuonion.kwrmyanmar;
import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;
@RunWith(FlutterTestRunner.class)
public class MainActivityTest {
  @Rule public ActivityTestRule<MainActivity> rule = new ActivityTestRule<>(MainActivity.class, true, false);
}
''')
p=Path('android/app/src/main/AndroidManifest.xml')
text=p.read_text().replace('<application','<uses-permission android:name="android.permission.INTERNET"/>\n    <application',1)
text=text.replace('android:label="kwrmyanmar"','android:label="KWR Myanmar"')
text=text.replace('<application','<application android:allowBackup="false" android:usesCleartextTraffic="false"',1)
text=text.replace('android:icon="@mipmap/ic_launcher"','android:icon="@drawable/kwr_icon"')
p.write_text(text)
icon=Path('android/app/src/main/res/drawable/kwr_icon.xml')
icon.parent.mkdir(parents=True,exist_ok=True)
icon.write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#176B58" android:pathData="M0,0h108v108h-108z"/>
    <path android:fillColor="#CAE6DC" android:pathData="M23,24h49v61h-49z"/>
    <path android:fillColor="#FFFFFF" android:pathData="M31,19h52v61h-52z"/>
    <path android:fillColor="#176B58" android:pathData="M40,30h32v5h-32z M40,42h25v5h-25z M40,54h21v5h-21z"/>
    <path android:fillColor="#D8B678" android:pathData="M65,65h23v23h-23z"/>
    <path android:strokeColor="#102E36" android:strokeWidth="4" android:fillColor="#00000000" android:pathData="M69,76l5,5l10,-11"/>
</vector>''')
Path('android/gradle.properties').write_text(Path('android/gradle.properties').read_text()+'\nandroid.enableJetifier=true\n')
print('Android: internet, minSdk 23, bundled Korean OCR, backup disabled')
