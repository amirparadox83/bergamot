# Bergamot ProGuard Rules
# ──────────────────────────────────────────────────────────────────────

# ── Flutter ──────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Drift / SQLite generated code ────────────────────────────────────
# Drift uses reflection-free code generation, but the generated adapters
# and companion classes must not be stripped.
-keep class com.bergamot.bergamot.** { *; }
-keep class drift.** { *; }
-dontwarn drift.**
-keep class com.squareup.sqlcipher.** { *; }

# ── Riverpod / State Management ──────────────────────────────────────
# Riverpod uses compile-time code generation via riverpod_generator.
# The generated *.g.dart files contain provider subclasses that must
# survive R8 shrinking.
-keepclassmembers class * {
    @riverpod *;
}
-dontwarn riverpod.**

# ── GoRouter ─────────────────────────────────────────────────────────
# GoRouter relies on string-based route matching. The route names and
# path parameters are kept through annotations and inner classes.
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ── JSON serialization (json_annotation / json_serializable) ─────────
# Keep generated fromJson/toJson factories and their enclosing classes.
-keep class **.g.** { *; }
-keep class **.**$** { *; }

# ── Suppress warnings for third-party libraries ──────────────────────
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.**
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
