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
            UserLocation.sharedInstance.updateLocationOffline(position: nil)
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
        TerminatedLocationManager.instance.start()
        UserLocation.sharedInstance.start()
    }
    func stop() {
        ForegroundLocationManager.instance.stop()
        BackgroundLocationManager.instance.stop()
        TerminatedLocationManager.instance.stop()
        UserLocation.sharedInstance.stop()
    }
}

class TerminatedLocationManager :NSObject {
    static let instance = TerminatedLocationManager()
    let locationManager = CLLocationManager()
    private override init(){
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.activityType = .other;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        if #available(iOS 9, *){
            locationManager.allowsBackgroundLocationUpdates = true
        }
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startMonitoringSignificantLocationChanges()
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationEnterTerminated), name: UIApplication.willTerminateNotification, object: nil)
    }
    @objc func applicationEnterTerminated(){
        start()
    }
    func start(){
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways){
            self.locationManager.startMonitoringSignificantLocationChanges()
            setupMonitorRegion()
        } else {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
    func setupMonitorRegion(){
        let lastLatitude =  UserDefaults.standard.double(forKey: "flutter.last_latitude")
        let lastLongitude = UserDefaults.standard.double(forKey: "flutter.last_longitude")
        if lastLatitude != 0 && lastLongitude != 0 {
           if CLLocationManager.authorizationStatus() == .authorizedAlways {
               if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                  let maxDistance = 100.0
                  let center = CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
                  let identifier = "\(lastLatitude)_\(lastLongitude)"
                  let region = CLCircularRegion(center: center, radius: maxDistance, identifier: identifier)
                  region.notifyOnEntry = true
                  region.notifyOnExit = true
                  locationManager.startMonitoring(for: region)
               }
           }
        }
    }
    func stop(){
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    func sendLocationToServer(location:CLLocation){
        updateLocation(location: location)
        UserLocation.sharedInstance.location = location
        UserLocation.sharedInstance.updateLocation()
    }
    func updateLocation(location:CLLocation) {
        UserLocation.sharedInstance.updateLocationOffline(position: nil)
        do {
            if let token = UserDefaults.standard.string(forKey: "flutter.access_token") {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let params = ["lat":location.coordinate.latitude,
                              "lng":location.coordinate.longitude,
                              "time": formatter.string(from: Date()),
                              "speed": location.speed
                ] as Dictionary<String, Any>
                var request = URLRequest(url: URL(string: "http://dev.api.ggigroup.org/api/children/tracking")!)
                request.httpMethod = "POST"
                request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                let session = URLSession.shared
                let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                        if let error = error {
                            UserLocation.sharedInstance.updateLocationOffline(position: location)
                        }
                })
                task.resume()
            }
        }catch(_) {}
    }
    func beginNewTerminatedTask(){
        if(LocationUpdate.shared.isStop)
        {
           return
        }
        start()
    }
}

extension TerminatedLocationManager : CLLocationManagerDelegate {
    func monitorRegionAtLocation(center: CLLocationCoordinate2D, identifier: String ) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
                let maxDistance = 100.0
                let region = CLCircularRegion(center: center,
                                              radius: maxDistance, identifier: identifier)
                region.notifyOnEntry = true
                region.notifyOnExit = true
                locationManager.startMonitoring(for: region)
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        beginNewTerminatedTask()
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case CLAuthorizationStatus.restricted: break
        case CLAuthorizationStatus.denied: break
        case CLAuthorizationStatus.notDetermined: break
        default:
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if let region = region as? CLCircularRegion {
            sendLocationToServer(location: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {return}
        sendLocationToServer(location: location)
        monitorRegionAtLocation(center: CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                                               longitude: location.coordinate.longitude), identifier: "\(location.coordinate.latitude)_\(location.coordinate.longitude)")
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            sendLocationToServer(location: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
        }
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let region = region as? CLCircularRegion {
            sendLocationToServer(location: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
            locationManager.stopMonitoring(for: region)
            setupMonitorRegion()
        }
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
    }
    @objc func applicationEnterBackground(){
        start()
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
    }
    @objc func applicationEnterForeground(){
        start()
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

open class Reachability {
    class func isLocationServiceEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .notDetermined, .restricted, .denied , .authorizedWhenInUse:
                LocationAlert().showAlertLocation()
            case .authorizedAlways :break
            default:
                print("Somethng error!")
            }
        } else {
            LocationAlert().showAlertLocation()
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
    var timeCallUpdateLocation = 30.0
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
                if duration >= 30 {
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

    // sharepreference đang lưu dạng { "trackings": [{"lat": "", "lng": "", "time": "", "speed": ""}] }
    func updateLocationOffline(position:CLLocation?) {
        do {
            var params:[Dictionary<String, Any>]?
            if position != nil {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                params = [["lat":position!.coordinate.latitude,
                           "lng":position!.coordinate.longitude,
                           "time": formatter.string(from: Date()),
                           "speed": position!.speed
                          ]] as [Dictionary<String, Any>]
            }
            UserDefaults.standard.synchronize()
            if let value = UserDefaults.standard.object(forKey: "flutter.tracking_offline") as? Dictionary<String, Any> {
                var arr:[Dictionary<String, Any>] = value["trackings"] as! [Dictionary<String, Any>]
                if let val = params {
                    arr += val
                }
                uploadOffline(value: ["trackings":arr])
            }
            else {
                if let val = params {
                    uploadOffline(value: ["trackings":val])
                }
            }
        }catch(_) {}
    }
    func uploadOffline(value:Dictionary<String, Any>) {
        DispatchQueue.global(qos: .utility).async {
            if let token = UserDefaults.standard.string(forKey: "flutter.access_token") {
                do {
                    let params = value
                    var request = URLRequest(url: URL(string: "http://dev.api.ggigroup.org/api/children/trackingOffline")!)
                    request.httpMethod = "POST"
                    request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    let session = URLSession.shared
                    let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                        if let error = error {
                            UserDefaults.standard.set(value, forKey: "flutter.tracking_offline")
                            UserDefaults.standard.synchronize()
                        }else{
                            UserDefaults.standard.removeObject(forKey: "flutter.tracking_offline")
                            UserDefaults.standard.synchronize()
                        }
                    })
                    task.resume()
                }catch(_) {}
            }
        }
    }
}

class LocationTracking {
    static let shared = LocationTracking()
    func updateCurrentLocation(lat:Double,lng:Double,speed:Double) {
        DispatchQueue.global(qos: .background).async {
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
