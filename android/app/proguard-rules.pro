# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Hive
-keep class * extends com.google.gson.TypeAdapter
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep model classes used with Hive reflection-free adapters
-keep class com.omniforge.ai.** { *; }

# Dio / OkHttp (used transitively by some plugins)
-dontwarn okhttp3.**
-dontwarn okio.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# local_auth
-keep class androidx.biometric.** { *; }

# General Android
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keep public class * extends java.lang.Exception
