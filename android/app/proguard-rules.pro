# ONNX Runtime (page translation OCR): its native code finds these classes,
# fields and constructors by name, and its AAR ships no keep rules, so R8
# would rename or drop them in release builds.
-keep class ai.onnxruntime.** { *; }
