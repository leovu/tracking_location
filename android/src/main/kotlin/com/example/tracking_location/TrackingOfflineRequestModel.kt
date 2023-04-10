package com.example.tracking_location

import com.google.gson.annotations.SerializedName

data class TrackingOfflineRequestModel (
    @SerializedName("trackings") val trackings:ArrayList<TrackingOfflineItemRequestModel>
)