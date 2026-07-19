# Fix Deprecated 'android.newDsl' Setting

The project is showing a deprecation warning because `android.newDsl=false` is set in `gradle.properties`. This setting is deprecated in Android Gradle Plugin (AGP) 9.x and will be removed in AGP 10.0.

However, enabling the new DSL (`android.newDsl=true`) currently causes a `NullPointerException` in the Flutter Gradle Plugin, as it still relies on legacy Android APIs that are disabled when the new DSL is enforced.

## Proposed Changes

To resolve the deprecation warning while maintaining compatibility with the Flutter build tools, we will downgrade the Android Gradle Plugin to a stable 8.x version where this setting is not yet deprecated.

### [Component Name] Gradle Configuration

#### [MODIFY] [settings.gradle.kts](file:///F:/multi_crop_disease_detector_app/android/settings.gradle.kts)
- Downgrade `com.android.application` version from `9.0.1` to `8.10.2`.
- Downgrade `org.jetbrains.kotlin.android` version from `2.2.20` to `2.0.21` (for better compatibility with AGP 8.x).

#### [MODIFY] [gradle-wrapper.properties](file:///F:/multi_crop_disease_detector_app/android/gradle/wrapper/gradle-wrapper.properties)
- Downgrade `distributionUrl` to use Gradle `8.10.2`.

## Verification Plan

### Automated Tests
- Run Gradle sync to ensure the project syncs successfully without the deprecation warning.
- Run a build to ensure the project still compiles.

### Manual Verification
- Verify that the IDE no longer shows the deprecation warning for `android.newDsl`.
