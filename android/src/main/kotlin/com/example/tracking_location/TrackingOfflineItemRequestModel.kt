package com.example.tracking_location

import com.google.gson.annotations.SerializedName

data class TrackingOfflineItemRequestModel (
    @SerializedName("lat") val lat:Any,
    @SerializedName("lng") val lng:Any,
    @SerializedName("time") val time:Any,
    @SerializedName("speed") val speed:Any,
)