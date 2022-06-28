package com.example.tracking_location
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

@SuppressLint("StaticFieldLeak")
object TrackingUpdate {
    var channel: MethodChannel? = null
    var isUpdateLocation: Boolean = false
    lateinit var context:Context

    fun tracking(action:Boolean) {
        if(action) {
            isUpdateLocation = true
            val intent = Intent(context, TimerService::class.java)
            context.stopService(intent)
            context.startService(intent)
        }
        else {
            isUpdateLocation = false
            val intent = Intent(context, TimerService::class.java)
            context.stopService(intent)
        }
    }
}