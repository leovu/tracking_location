package com.example.tracking_location

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import com.google.android.gms.location.LocationResult
import okhttp3.OkHttpClient
import retrofit2.Call
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class GPSTrackerReceiver: BroadcastReceiver() {
    private val KEY_SHARE_PREFS = "FlutterSharedPreferences"
    private val url: String = "http://dev.api.ggigroup.org/api/"

    private lateinit var mRefs: SharedPreferences
    private lateinit var token: String

    private val ACTION_PROCESS_UPDATES = "com.google.android.c2dm.intent.LOCATION"

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent != null) {
            val action = intent.action
            if (ACTION_PROCESS_UPDATES == action) {
                val result = LocationResult.extractResult(intent)
                if (result != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val locations = result.lastLocation
                    getPreference(context)
                    try{
                        if (token != "") {
                            val now = LocalDateTime.now()
                            val map = mapOf(
                            "lat" to locations.latitude,
                            "lng" to locations.longitude,
                            "time" to now.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")),
                            "speed" to locations.speed
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
}
