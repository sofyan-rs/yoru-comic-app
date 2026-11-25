package org.kurodev.yoru

import android.app.Application
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

/**
 * Store build: no Mihon host (the `:mihon` module is not linked). The
 * `yoru/mihon` channel stays unregistered; Dart never asks for Mihon
 * (`AppVariables.storeBuild`) and takes a missing `setDns` handler in its
 * stride.
 */
internal object MihonGlue {
    fun onAppCreate(app: Application) {}

    fun attach(context: Context, messenger: BinaryMessenger) {}
}
