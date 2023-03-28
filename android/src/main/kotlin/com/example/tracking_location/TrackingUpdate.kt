package com.example.tracking_location
import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices

@SuppressLint("StaticFieldLeak")
object TrackingUpdate {
    private var mLocationRequest: LocationRequest? = null
    private val UPDATE_INTERVAL = (30000).toLong()
    private val FASTEST_UPDATE_INTERVAL = UPDATE_INTERVAL / 2
    private val MAX_WAIT_TIME = UPDATE_INTERVAL * 2
    private val ACTION_PROCESS_UPDATES = "com.google.android.c2dm.intent.LOCATION"

    lateinit var context:Context

    fun tracking(action:Boolean) {
        if(action) {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                && ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                createLocationRequest()
            }
        }
        else {
            destroyLocationRequest()
        }
    }

    private fun createLocationRequest() {
        if (mLocationRequest == null) {
            mLocationRequest = LocationRequest()

            mLocationRequest!!.interval = UPDATE_INTERVAL
            mLocationRequest!!.fastestInterval = FASTEST_UPDATE_INTERVAL
            mLocationRequest!!.maxWaitTime = MAX_WAIT_TIME
            mLocationRequest!!.priority = LocationRequest.PRIORITY_HIGH_ACCURACY

            LocationServices.getFusedLocationProviderClient(context).requestLocationUpdates(
                mLocationRequest, getPendingIntent())
        }
    }

    private fun getPendingIntent(): PendingIntent {
        val intent = Intent(context, GPSTrackerReceiver::class.java)
        intent.action = ACTION_PROCESS_UPDATES
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else {
            PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT
            )
        }
    }

    private fun destroyLocationRequest() {
        if (mLocationRequest != null) {
            LocationServices.getFusedLocationProviderClient(context).removeLocationUpdates(getPendingIntent())
            mLocationRequest = null
        }
    }
}