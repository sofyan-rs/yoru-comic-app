package sk.fourq.otaupdate

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Store build stand-in for ota_update's plugin, whose project is excluded
 * (android/app/build.gradle): GeneratedPluginRegistrant still names this
 * class. It registers nothing, so the app holds no APK installer; Dart
 * never calls it, as a store build does not check for updates.
 */
class OtaUpdatePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
