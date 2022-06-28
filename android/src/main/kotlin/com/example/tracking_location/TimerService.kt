package com.example.tracking_location

import android.app.Service
import android.content.Intent
import android.location.Location
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.annotation.Nullable
import java.util.*


class TimerService : Service() {
    private var mTimer: Timer? = null
    private var intent: Intent? = null
    private val UPDATE_INTERVAL = (30000).toLong()
    private var lastTimeUpdate: String = ""
    @Nullable
    override fun onBind(intent: Intent): IBinder? {
        return null
    }
    override fun onCreate() {
        super.onCreate()
        mTimer = Timer()
        mTimer!!.scheduleAtFixedRate(TimeDisplayTimerTask(), 1, NOTIFY_INTERVAL)
        intent = Intent(str_receiver)
    }
    internal inner class TimeDisplayTimerTask : TimerTask() {
        override fun run() {
            Handler(Looper.getMainLooper()).postDelayed({
                val currentTime = Calendar.getInstance().timeInMillis
                if(TrackingUpdate.isUpdateLocation) {
                    if(lastTimeUpdate != ""){
                        val lastTime = lastTimeUpdate.toLong()
                        val time = currentTime - lastTime
                        if(time < UPDATE_INTERVAL) {
                            lastTimeUpdate = currentTime.toString()
                            sendLocation()
                        }
                    }
                    else {
                        sendLocation()
                    }
                }
            }, 30000)
        }
    }
    private fun sendLocation(){
        val locationResult = object : MyLocation.LocationResult() {
            override fun gotLocation(location: Location?) {
                val lat = location!!.latitude
                val lng = location.longitude
                val map = mapOf("lat" to lat, "lng" to lng)
                TrackingUpdate.channel?.invokeMethod("update_location", map)
            }
        }
        val myLocation = MyLocation()
        myLocation.getLocation(TrackingUpdate.context, locationResult)
    }
    override fun onDestroy() {
        super.onDestroy()
        Log.e("Service finish", "Finish")
    }
    private fun fn_update(str_time: String) {
        intent!!.putExtra("time", str_time)
        sendBroadcast(intent)
    }
    companion object {
        var str_receiver = "com.countdowntimerservice.receiver"
        const val NOTIFY_INTERVAL: Long = 30000
    }
}