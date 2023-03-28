package com.example.tracking_location

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.util.Log

@Suppress("DEPRECATION")
object Util {
    fun isMyServiceRunning(serviceClass: Class<*>, context: Context): Boolean {
        val manager: ActivityManager =
            context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        for (service in manager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                Log.e("Service status", "Running")
                return true
            }
        }
        Log.e("Service status", "Not running")
        return false
    }
}