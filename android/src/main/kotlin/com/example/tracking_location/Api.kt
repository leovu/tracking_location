package com.example.tracking_location

import retrofit2.Call
import retrofit2.http.*

interface Api {
    @JvmSuppressWildcards
    @POST("children/tracking")
    fun sendLocation(
        @Body body: Map<String, Any>
    ): Call<ResponseModel>
}