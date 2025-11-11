package com.example.itracelink

import androidx.multidex.MultiDex
import androidx.multidex.MultiDexApplication
import android.content.Context

class Application : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        // Initialize Firebase and other services here if needed
    }

    override fun attachBaseContext(base: Context?) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}
