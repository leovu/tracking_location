package com.example.tracking_location

import android.Manifest
import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.graphics.Color
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.*
import com.google.android.gms.location.LocationRequest.*
import com.google.gson.Gson
import com.google.gson.JsonArray
import okhttp3.OkHttpClient
import org.json.JSONArray
import org.json.JSONObject
import retrofit2.Call
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*
import kotlin.collections.ArrayList

class LocationService : Service() {

    lateinit var mContext: Context

    private val KEY_SHARE_PREFS = "FlutterSharedPreferences"
    private val url: String = "http://dev.api.ggigroup.org/api/"

    private lateinit var mRefs: SharedPreferences
    private lateinit var token: String

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private val locationRequest: LocationRequest = create().apply {
        interval = 10000
        fastestInterval = 5000
        priority = PRIORITY_BALANCED_POWER_ACCURACY
        maxWaitTime = 30000
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
        if(isNetworkAvailable(context = mContext)){
            Log.e("TAG", "isNetworkAvailable")
            Log.e("Send location url", url)
            Log.e("Send location token", token)
            Log.e("Send location params", map.toString())
            val trackingOffline = mRefs.getString("flutter.tracking_offline","")!!
            if(trackingOffline != ""){
                var trackingOfflineRequestModel =  Gson().fromJson<TrackingOfflineRequestModel>(trackingOffline, TrackingOfflineRequestModel::class.java)
                var model = TrackingOfflineItemRequestModel(lat = map["lat"]!!, lng = map["lng"]!!, time = map["time"]!!, speed = map["speed"]!!)
                trackingOfflineRequestModel.trackings.add(model)

                retrofit.create(Api::class.java).trackingOffline(trackingOfflineRequestModel)
                    .enqueue(object: retrofit2.Callback<ResponseModel>{
                        override fun onFailure(call: Call<ResponseModel>, t: Throwable) {
                            mRefs.edit().putString("flutter.tracking_offline", Gson().toJson(trackingOfflineRequestModel))
                            mRefs.edit().apply()
                        }

                        @SuppressLint("CommitPrefEdits")
                        override fun onResponse(call: Call<ResponseModel>, response: Response<ResponseModel>) {
                            mRefs.edit().putString("flutter.tracking_offline","")
                            mRefs.edit().apply()
                        }

                    })
            }else{
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

        }else{
            Log.e("TAG", "NetworkUnavailable")
            val trackingOffline = mRefs.getString("flutter.tracking_offline","")!!
            var trackingOfflineRequestModel:TrackingOfflineRequestModel
            var model = TrackingOfflineItemRequestModel(lat = map["lat"]!!, lng = map["lng"]!!, time = map["time"]!!, speed = map["speed"]!!)
            if(trackingOffline != ""){
                trackingOfflineRequestModel = Gson().fromJson(trackingOffline, TrackingOfflineRequestModel::class.java)
            }else{
                trackingOfflineRequestModel = TrackingOfflineRequestModel(trackings =  kotlin.collections.ArrayList())
            }
            trackingOfflineRequestModel.trackings.add(model)
            mRefs.edit().putString("flutter.tracking_offline", Gson().toJson(trackingOfflineRequestModel))
            mRefs.edit().apply()
        }

    }

    fun isNetworkAvailable(context: Context?): Boolean {
        if (context == null) return false
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val capabilities = connectivityManager.getNetworkCapabilities(connectivityManager.activeNetwork)
            if (capabilities != null) {
                when {
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                        return true
                    }
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> {
                        return true
                    }
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> {
                        return true
                    }
                }
            }
        } else {
            val activeNetworkInfo = connectivityManager.activeNetworkInfo
            if (activeNetworkInfo != null && activeNetworkInfo.isConnected) {
                return true
            }
        }
        return false
    }

    override fun onCreate() {
        super.onCreate()
        mContext = this

        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)

        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.O) createNotificationChanel() else startForeground(1, Notification())

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
    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChanel() {
        val notificationChannelId = "Location channel id"
        val channelName = "Background Service"
        val chan = NotificationChannel(notificationChannelId, channelName, NotificationManager.IMPORTANCE_NONE)
        chan.lightColor = Color.BLUE
        chan.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        val manager = (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
        manager.createNotificationChannel(chan)
        val notificationBuilder =
            NotificationCompat.Builder(this, notificationChannelId)
        val notification: Notification = notificationBuilder.setOngoing(true)
            .setContentTitle("Location updates:")
            .setPriority(NotificationManager.IMPORTANCE_MIN)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()

        startForeground(2, notification)
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