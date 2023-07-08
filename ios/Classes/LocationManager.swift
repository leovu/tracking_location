//
//  LocationManager.swift
//
//

import Foundation
import CoreLocation
import UIKit
import Flutter

class LocationUpdate {
    static let shared = LocationUpdate()
    let locationManager = CLLocationManager()
    var isStop:Bool = true
    var methodChannel:FlutterMethodChannel?
    func tracking(action:Bool) {
        self.isStop = action
        if action == true {
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            locationManager.activityType = .other;
            locationManager.distanceFilter = kCLDistanceFilterNone;
            if #available(iOS 9, *){
                locationManager.allowsBackgroundLocationUpdates = true
            }
            locationManager.startUpdatingLocation()
            LocationManger.instance.start()
        }
        else {
            LocationManger.instance.stop()
        }
    }
}

class LocationManger:NSObject {
    static let instance = LocationManger()
    func start() {
        ForegroundLocationManager.instance.start()
        BackgroundLocationManager.instance.start()
        UserLocation.sharedInstance.start()
    }
    func stop() {
        ForegroundLocationManager.instance.stop()
        BackgroundLocationManager.instance.stop()
        UserLocation.sharedInstance.stop()
    }
}

class BackgroundLocationManager :NSObject {
    static let instance = BackgroundLocationManager()
    static let BACKGROUND_TIMER = 150.0 // restart location manager every 150 seconds
    static let UPDATE_SERVER_INTERVAL = 1
    let locationManager = CLLocationManager()
    var timer:Timer?
    var currentBgTaskId : UIBackgroundTaskIdentifier?
    private override init(){
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.activityType = .other;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        if #available(iOS 9, *){
            locationManager.allowsBackgroundLocationUpdates = true
        }
        locationManager.startUpdatingLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.willTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    @objc func applicationEnterBackground(){
        start()
    }
    @objc func willTerminate(){
        stop()
    }
    func start(){
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    func stop(){
        if(timer != nil){timer!.invalidate()}
        if (currentBgTaskId != nil) {
            UIApplication.shared.endBackgroundTask(currentBgTaskId!)
            currentBgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        locationManager.stopUpdatingLocation()
    }
    @objc func restart (){
        timer?.invalidate()
        timer = nil
        start()
    }
    func sendLocationToServer(location:CLLocation){
        UserLocation.sharedInstance.location = location
        UserLocation.sharedInstance.update()
    }
    func beginNewBackgroundTask(){
        if(LocationUpdate.shared.isStop)
        {
           return
        }
        var previousTaskId = currentBgTaskId;
        currentBgTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: {
        })
        if let taskId = previousTaskId{
            UIApplication.shared.endBackgroundTask(taskId)
            previousTaskId = UIBackgroundTaskIdentifier.invalid
        }
        timer = Timer.scheduledTimer(timeInterval: BackgroundLocationManager.BACKGROUND_TIMER, target: self, selector: #selector(self.restart),userInfo: nil, repeats: false)
    }
}

extension BackgroundLocationManager : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        beginNewBackgroundTask()
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case CLAuthorizationStatus.restricted: break
        case CLAuthorizationStatus.denied: break
        case CLAuthorizationStatus.notDetermined: break
        default:
            locationManager.startUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        sendLocationToServer(location: location)
        locationManager.startUpdatingLocation()
        if(timer==nil){
            beginNewBackgroundTask()
        }
    }
    
}

class ForegroundLocationManager :NSObject {
    static let instance = ForegroundLocationManager()
    static let BACKGROUND_TIMER = 150.0 // restart location manager every 150 seconds
    static let UPDATE_SERVER_INTERVAL = 1
    let locationManager = CLLocationManager()
    var timer:Timer?
    var currentBgTaskId : UIBackgroundTaskIdentifier?
    private override init(){
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.activityType = .other;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        if #available(iOS 9, *){
            locationManager.allowsBackgroundLocationUpdates = true
        }
        locationManager.startUpdatingLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.willTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    @objc func applicationEnterForeground(){
        start()
    }
    @objc func willTerminate(){
        stop()
    }
    func start(){
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    func stop(){
        if(timer != nil){timer!.invalidate()}
        if (currentBgTaskId != nil) {
            UIApplication.shared.endBackgroundTask(currentBgTaskId!)
            currentBgTaskId = UIBackgroundTaskIdentifier.invalid
        }
        locationManager.stopUpdatingLocation()
    }
    @objc func restart (){
        timer?.invalidate()
        timer = nil
        start()
    }
    func sendLocationToServer(location:CLLocation){
        UserLocation.sharedInstance.location = location
        UserLocation.sharedInstance.update()
    }
    func beginNewForegroundTask(){
        if(LocationUpdate.shared.isStop)
        {
           return
        }
        var previousTaskId = currentBgTaskId;
        currentBgTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            
        })
        if let taskId = previousTaskId{
            UIApplication.shared.endBackgroundTask(taskId)
            previousTaskId = UIBackgroundTaskIdentifier.invalid
        }
        
        timer = Timer.scheduledTimer(timeInterval: ForegroundLocationManager.BACKGROUND_TIMER, target: self, selector: #selector(self.restart),userInfo: nil, repeats: false)
    }
}

extension ForegroundLocationManager : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        beginNewForegroundTask()
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case CLAuthorizationStatus.restricted: break
        case CLAuthorizationStatus.denied: break
        case CLAuthorizationStatus.notDetermined: break
        default:
            locationManager.startUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        sendLocationToServer(location: location)
        locationManager.startUpdatingLocation()
        if(timer==nil){
            beginNewForegroundTask()
        }
    }
    
}

open class LocationAlert {
    let locationManager = CLLocationManager()
    func showAlertLocation(){
        if UserDefaults.standard.bool(forKey: "AccountLoggedIn") {
            let alert = UIAlertController(title: "Thông báo", message: "Bạn phải cho phép ứng dụng truy cập vị trí hiện tại của bạn ở chế độ 'Luôn luôn/Always' !", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Thông báo", style: UIAlertAction.Style.default, handler: {action in
                if !CLLocationManager.locationServicesEnabled() {
                    if let url = URL(string: "App-Prefs:root=Privacy&path=LOCATION") {
                        // If general location settings are disabled then open general location settings
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url as URL, options: [ : ]) { (success) in
                                if success{
                                    print("Its working fine")
                                }else{
                                    print("You ran into problem")
                                }
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                } else {
                    if let url = URL(string:UIApplication.openSettingsURLString) {
                        // If general location settings are enabled then open location settings for the app
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url as URL, options: [ : ]) { (success) in
                                if success{
                                    print("Its working fine")
                                }else{
                                    print("You ran into problem")
                                }
                            }
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
            }))
            if let topVC = UIApplication.topViewController() {
                topVC.present(alert, animated: true, completion: nil)
            }
        }
        else { return }
    }
}

final class UserLocation {
    static let sharedInstance = UserLocation()
    var timer:Timer?
    var location:CLLocation?
    var lastLocation:CLLocation?
    var lastTime:Date?
    var timeCallUpdateLocation = 5.0
    private init() { }
    func start(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.update()
        }
        timer = Timer.scheduledTimer(timeInterval: timeCallUpdateLocation, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    func stop(){
        if(timer != nil){timer!.invalidate()}
    }
    @objc func update() {
        DispatchQueue.main.async {
            guard self.location != nil else { return }
            if self.lastTime == nil {
                self.lastTime = Date()
                self.updateLocation()
            }
            else {
                let difference = Calendar.current.dateComponents([.second], from: self.lastTime!, to: Date())
                let duration = difference.second ?? 0
                if duration >= timeCallUpdateLocation {
                    self.updateLocation()
                }
            }
        }
    }
    func updateLocation() {
        self.lastTime = Date()
        self.lastLocation = self.location
        LocationTracking.shared.updateCurrentLocation(lat: self.location!.coordinate.latitude, lng: self.location!.coordinate.longitude, speed: Double(self.location!.speed))
    }
}

class LocationTracking {
    static let shared = LocationTracking()
    func updateCurrentLocation(lat:Double,lng:Double,speed:Double) {
        DispatchQueue.main.async {
            LocationUpdate.shared.methodChannel?.invokeMethod("update_location", arguments: [
                "lat":lat,
                "lng":lng,
                "speed":speed
            ])
        }
    }
}

extension Date {
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
extension UIApplication {
    class func topViewController(_ viewController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(presented)
        }
        return viewController
    }
}
extension DispatchQueue {
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }

}
