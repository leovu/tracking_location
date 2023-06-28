package com.example.tracking_location

import android.content.SharedPreferences
import com.google.gson.Gson
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import java.io.BufferedReader
import java.io.DataOutputStream
import java.io.IOException
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL


class TokenAuthenticator(private val mRefs: SharedPreferences, private val url: String, private val refreshToken: String): Authenticator {
    override fun authenticate(route: Route, response: Response): Request? {
        val refreshResult: RefreshTokenResult? = refreshToken(url, refreshToken)
        return if (refreshResult != null) {
            //token moi cua ban day
            val accessToken = refreshResult.data!!.token!!.accessToken
            val refreshToken = refreshResult.data!!.token!!.refreshToken
            mRefs.edit().apply {
                putString("flutter.access_token", accessToken)
                putString("flutter.refresh_token", refreshToken)
                apply()
            }
            // thuc hien request hien tai khi da lay duoc token moi
            response.request().newBuilder().header("Authorization", accessToken).build()
        } else {
            //Khi refresh token failed ban co the thuc hien action refresh lan tiep theo
            null
        }
    }

    @Throws(IOException::class)
    fun refreshToken(url: String, refresh: String): RefreshTokenResult? {
        val refreshUrl = URL(url + "refresh-token")
        val urlConnection = refreshUrl.openConnection() as HttpURLConnection
        urlConnection.doInput = true
        urlConnection.requestMethod = "POST"
        urlConnection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
        urlConnection.useCaches = false
        val urlParameters = ("refresh_token=$refresh")
        urlConnection.doOutput = true
        val wr = DataOutputStream(urlConnection.outputStream)
        wr.writeBytes(urlParameters)
        wr.flush()
        wr.close()
        val responseCode = urlConnection.responseCode
        if (responseCode == 200) {
            val `in` = BufferedReader(InputStreamReader(urlConnection.inputStream))
            var inputLine: String?
            val response = StringBuffer()
            while (`in`.readLine().also { inputLine = it } != null) {
                response.append(inputLine)
            }
            `in`.close()
            val gson = Gson()
            return gson.fromJson(
                response.toString(),
                RefreshTokenResult::class.java
            );
        } else {
            return null
        }
    }
}