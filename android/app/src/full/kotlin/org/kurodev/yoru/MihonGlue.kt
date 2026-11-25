package org.kurodev.yoru

import android.app.Application
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import org.kurodev.yoru.mihon.MihonHost
import org.kurodev.yoru.mihon.MihonProxy
import org.kurodev.yoru.mihon.supported

/** Where the app reaches the Mihon host; a store build has a no-op copy (src/store). */
internal object MihonGlue {
    /**
     * Background downloads of Mihon pages may run with no activity and no
     * Dart (WorkManager after the app was closed): the local server they
     * fetch from has to be up with the process.
     */
    fun onAppCreate(app: Application) {
        if (MihonHost.supported) runCatching { MihonProxy.start(app) }
    }

    fun attach(context: Context, messenger: BinaryMessenger) {
        MihonChannel(context, messenger)
    }
}
