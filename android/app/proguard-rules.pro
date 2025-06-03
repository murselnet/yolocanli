# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Kamera ve ML Kit için kurallar
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class androidx.camera.** { *; }

# Google Play Core için kurallar
-keep class com.google.android.play.core.** { *; }

# Diğer kullanılan kütüphaneler için kurallar
-keep class androidx.core.app.CoreComponentFactory { *; }
-keep class androidx.multidex.** { *; }

# Serialization kütüphaneleri için kurallar
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn sun.misc.**

# Kotlin için gerekli kurallar
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Genel kurallar
-dontoptimize
-dontpreverify
-dontshrink
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose 