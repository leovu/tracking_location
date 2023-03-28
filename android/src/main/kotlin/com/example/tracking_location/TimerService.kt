package com.example.tracking_location

import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.annotation.Nullable
import okhttp3.OkHttpClient
import retrofit2.Call
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*


class TimerService : Service() {

    private val KEY_SHARE_PREFS = "FlutterSharedPreferences"
    private val url: String = "http://dev.api.ggigroup.org/api/"
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
//            Handler(Looper.getMainLooper()).postDelayed({
//                val currentTime = Calendar.getInstance().timeInMillis
//                if(TrackingUpdate.isUpdateLocation) {
//                    if(lastTimeUpdate != ""){
//                        val lastTime = lastTimeUpdate.toLong()
//                        val time = currentTime - lastTime
//                        if(time < UPDATE_INTERVAL) {
//                            lastTimeUpdate = currentTime.toString()
//                            sendLocation()
//                        }
//                    }
//                    else {
//                        sendLocation()
//                    }
//                }
//            }, 30000)
        }
    }

    private fun sendLocation(){
        val locationResult = object : MyLocation.LocationResult() {
            override fun gotLocation(location: Location?) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val lat = location!!.latitude
                    val lng = location.longitude
                    val speed = location.speed
                    val now = LocalDateTime.now()
                    val map = mapOf(
                        "lat" to lat,
                        "lng" to lng,
                        "time" to now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")),
                        "speed" to speed
                    )

                    sendLocation(TrackingUpdate.context, map)
                }
            }
        }
        val myLocation = MyLocation()
        myLocation.getLocation(TrackingUpdate.context, locationResult)
    }

    private fun sendLocation(context: Context?, map: Map<String, Any>){
        val prefs = context!!.getSharedPreferences(KEY_SHARE_PREFS, Context.MODE_PRIVATE)
        val token = prefs.getString("flutter.access_token", "")!!

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