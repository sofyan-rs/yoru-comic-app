package org.kurodev.yoru

import android.app.Application

class YoruApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MihonGlue.onAppCreate(this)
    }
}
