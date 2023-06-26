package com.example.tracking_location

import com.google.gson.annotations.SerializedName

data class RefreshTokenResult (

    @SerializedName("error_description" ) var errorDescription : String? = null,
    @SerializedName("error_code"        ) var errorCode        : Int?    = null,
    @SerializedName("data"              ) var data             : Data?   = Data()

)
data class Data (
    @SerializedName("token"         ) var token        : Token?    = Token(),
)

data class Token (
    @SerializedName("access_token"  ) var accessToken  : String? = null,
    @SerializedName("token_type"    ) var tokenType    : String? = null,
    @SerializedName("expired_at"    ) var expiredAt    : String? = null,
    @SerializedName("refresh_token" ) var refreshToken : String? = null

)