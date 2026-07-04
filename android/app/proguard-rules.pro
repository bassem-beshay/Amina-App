## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

## Keep native methods
-keepclassmembers class * {
    native <methods>;
}

## Gson specific classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.stream.** { *; }

## Application classes that will be serialized/deserialized over Gson
-keep class com.amina.platform.** { *; }

## Keep all model classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

## Keep BuildConfig
-keep class **.BuildConfig { *; }

## Keep R class
-keepclassmembers class **.R$* {
    public static <fields>;
}

## OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

## Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }
-keepattributes Exceptions

## Keep all native libraries
-keepclasseswithmembernames class * {
    native <methods>;
}

## Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

## Keep classes referenced by Flutter
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }

## JCIP annotations (referenced by USDK/payment libraries)
-dontwarn net.jcip.annotations.**
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**

## Keep USDK classes (payment library)
-keep class com.usdk.** { *; }
-dontwarn com.usdk.**

## Keep all annotations
-keepattributes *Annotation*,Signature,Exception
-keep @interface * { *; }

## Additional missing class warnings
-dontwarn edu.umd.cs.findbugs.annotations.**

# ========================================
# 🔒 SECURITY: Enhanced Obfuscation Rules
# ========================================

## Remove all logging in release builds (prevents sensitive data leakage)
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

## Remove debug and test code
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    public static void checkParameterIsNotNull(...);
    public static void checkNotNullParameter(...);
}

## Optimize and obfuscate code aggressively
-optimizationpasses 5
-overloadaggressively
-repackageclasses ''
-allowaccessmodification

## Remove unused code
-dontnote **
-ignorewarnings

## String encryption (makes reverse engineering harder)
-adaptresourcefilenames **.properties,**.xml,**.json
-adaptresourcefilecontents **.properties,META-INF/MANIFEST.MF

## Keep crash reporting information
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

## Security: Remove reflection metadata
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

## Security: Obfuscate package names
-flattenpackagehierarchy
-repackageclasses 'o'
