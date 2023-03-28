package com.example.tracking_location
import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

@SuppressLint("StaticFieldLeak")
object TrackingUpdate {
    var mLocationService: LocationService = LocationService()
    lateinit var mServiceIntent: Intent

    lateinit var context:Context

    fun tracking(action:Boolean) {
        if(action) {
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
                && ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                starServiceFunc()
            }
        }
        else {
            stopServiceFunc()
        }
    }

    private fun starServiceFunc(){
        mLocationService = LocationService()
        mServiceIntent = Intent(context, mLocationService.javaClass)
        if (!Util.isMyServiceRunning(mLocationService.javaClass, context)) {
            context.startService(mServiceIntent)
        }
    }

    private fun stopServiceFunc(){
        mLocationService = LocationService()
        mServiceIntent = Intent(context, mLocationService.javaClass)
        if (Util.isMyServiceRunning(mLocationService.javaClass, context)) {
            context.stopService(mServiceIntent)
        }
    }
}