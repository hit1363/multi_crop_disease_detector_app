# Fix NullPointerException in Flutter Gradle Plugin with AGP 9.0.1

The project is failing to sync with a `java.lang.NullPointerException` in `com.flutter.gradle.FlutterPluginUtils.getLegacyAndroidExtension`. This is caused by breaking changes in Android Gradle Plugin (AGP) 9.0, where the "New DSL" is enabled by default. This hides legacy extension classes that the current version of the Flutter Gradle Plugin relies on.

## Proposed Changes

### [android]

#### [MODIFY] [gradle.properties](file:///F:/multi_crop_disease_detector_app/android/gradle.properties)
- Add compatibility flags to opt-out of the AGP 9.0 New DSL and built-in Kotlin support. This allows the Flutter plugin to access the legacy Android extension it expects.

#### [MODIFY] [app/build.gradle.kts](file:///F:/multi_crop_disease_detector_app/android/app/build.gradle.kts)
- Explicitly apply the `org.jetbrains.kotlin.android` plugin. Since we are opting out of AGP 9's built-in Kotlin support, we need to apply the standard Kotlin plugin to handle Kotlin compilation and the `kotlin { ... }` block.

## Verification Plan

### Automated Tests
- Run Gradle sync to verify that the `NullPointerException` is resolved and the project configures successfully.
- Run `./gradlew :app:assembleDebug` to ensure the build completes.

### Manual Verification
- Verify that the IDE no longer shows the sync error.
