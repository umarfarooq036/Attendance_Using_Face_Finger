# ZKTeco SDK
-keep class com.zkteco.android.biometric.** { *; }
-keep class com.zkteco.android.biometric.core.** { *; }
-keep class com.zkteco.android.biometric.module.** { *; }
-dontwarn com.zkteco.android.biometric.**

# Flutter Method Channel
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.android.FlutterActivity { *; }

# USB and Reflection
-keep class android.hardware.usb.** { *; }
-keepattributes *Annotation*
-keepattributes Signature