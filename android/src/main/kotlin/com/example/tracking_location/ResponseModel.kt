package com.example.tracking_location

import com.google.gson.annotations.SerializedName

data class ResponseModel (
    @SerializedName("error_code") val errorCode:Int,
    @SerializedName("error_description") val errorDescription:String,
    @SerializedName("data") val data:Any,
)