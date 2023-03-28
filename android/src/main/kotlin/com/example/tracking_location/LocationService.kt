package com.example.tracking_location

import android.Manifest
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.*
import com.google.android.gms.location.LocationRequest.*
import okhttp3.OkHttpClient
import retrofit2.Call
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

class LocationService : Service() {

    lateinit var mContext: Context

    private val KEY_SHARE_PREFS = "FlutterSharedPreferences"
    private val url: String = "http://dev.api.ggigroup.org/api/"

    private lateinit var mRefs: SharedPreferences
    private lateinit var token: String

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private val locationRequest: LocationRequest = create().apply {
        interval = 3000
        fastestInterval = 3000
        priority = PRIORITY_BALANCED_POWER_ACCURACY
        maxWaitTime = 5000
    }

    private var locationCallback: LocationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            val locationList = locationResult.locations
            if (locationList.isNotEmpty()) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val location = locationList.last()
                    getPreference(mContext)
                    try{
                        if (token != "") {
                            val now = LocalDateTime.now()
                            val map = mapOf(
                                "lat" to location.latitude,
                                "lng" to location.longitude,
                                "time" to now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")),
                                "speed" to location.speed
                            )
                            sendLocation(map)

                        }
                    }
                    catch (_: Exception){}
                }
            }
        }
    }

    private fun getPreference(context: Context?) {
        mRefs = context!!.getSharedPreferences(KEY_SHARE_PREFS, Context.MODE_PRIVATE)
        token = mRefs.getString("flutter.access_token","")!!
    }

    private fun sendLocation(map: Map<String, Any>){

        Log.e("Send location url", url)
        Log.e("Send location token", token)
        Log.e("Send location params", map.toString())

        val httpClient = OkHttpClient.Builder().addInterceptor { chain ->
            val original = chain.request()

            val requestBuilder = original
                .newBuilder()
                .addHeader("Content-Type", "application/json")
                .addHeader("Authorization", "Bearer $token")
                .method(original.method(), original.body())

            val request = requestBuilder.build()
            chain.proceed(request)
        }.build()

        val retrofit = Retrofit.Builder().baseUrl(url).addConverterFactory(GsonConverterFactory.create()).client(httpClient).build()
        retrofit.create(Api::class.java).sendLocation(map)
            .enqueue(object: retrofit2.Callback<ResponseModel>{
                override fun onFailure(call: Call<ResponseModel>, t: Throwable) {
                    Log.e("onFailure", t.message.toString())
                }

                override fun onResponse(call: Call<ResponseModel>, response: Response<ResponseModel>) {
                    Log.e("onResponse", response.body()?.toString()!!)
                }

            })
    }

    override fun onCreate() {
        super.onCreate()
        mContext = this

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
            != PackageManager.PERMISSION_GRANTED
            && ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION)
            != PackageManager.PERMISSION_GRANTED) {

            Toast.makeText(applicationContext, "Permission required", Toast.LENGTH_LONG).show()
            return
        }else{
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper())
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        return START_STICKY
    }
    override fun onDestroy() {
        super.onDestroy()
        fusedLocationClient.removeLocationUpdates(locationCallback)
    }
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}