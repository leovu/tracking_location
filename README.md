# tracking_location

Tracking Location Flutter project.

## Android

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_LOCATION_EXTRA_COMMANDS" />
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
    <uses-permission android:name="android.hardware.location.gps" />
    <application>
        <service android:name="com.example.tracking_location.LocationService" />
    </application>


## iOS

    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Ứng dụng cần bạn chấp nhận cho truy cập vị trí để sử dụng chức năng hỗ trợ vị trí của bạn</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Ứng dụng cần bạn chấp nhận cho truy cập vị trí để sử dụng chức năng hỗ trợ vị trí của bạn</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Ứng dụng cần bạn chấp nhận cho truy cập vị trí để sử dụng chức năng hỗ trợ vị trí của bạn</string>

    ......
    <key>UIBackgroundModes</key>
	<array>
		<string>location</string>
	</array>

## Flutter
    import 'package:tracking_location/tracking_location.dart';

    Future<void> init() async {
        int result = await _trackingLocationPlugin.start();
        if(result == 1) {
            _trackingLocationPlugin.listen(getLocationUpdate);
        }
        setState(() {
            status = result;
        });
    }

    void getLocationUpdate(dynamic value) {
        print(value);
    }

    'Tracking service is: ${(status == null) ? 'Unavailable' : (status == 0) ? 'Stop' : 'Running'}'
