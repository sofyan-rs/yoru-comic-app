# ONNX Runtime (page translation OCR): its native code finds these classes,
# fields and constructors by name, and its AAR ships no keep rules, so R8
# would rename or drop them in release builds.
-keep class ai.onnxruntime.** { *; }

# ML Kit (page translation, ML Kit engine): Firebase's component discovery
# creates each registrar by reflection, through its no-argument
# constructor, which R8 otherwise removes; the translator then never
# starts and every call fails as a MissingPluginException.
-keep class * implements com.google.firebase.components.ComponentRegistrar { public <init>(); }
-keep class com.google.mlkit.nl.translate.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_translation.** { *; }
