//
//  Reachability.swift
//  tracking_location
//
//  Created by Long Vu on 11/04/2023.
//

import Network


@available(iOS 12.0, *)
struct Internet {
    private static let monitor = NWPathMonitor()
 static var active = false
 static var expensive = false
 
 /// Monitors internet connectivity changes. Updates with every change in connectivity.
 /// Updates variables for availability and if it's expensive (cellular).
 static func start() {
  guard monitor.pathUpdateHandler == nil else { return }
  
  monitor.pathUpdateHandler = { update in
   Internet.active = update.status == .satisfied ? true : false
   Internet.expensive = update.isExpensive ? true : false
  }
  
  monitor.start(queue: DispatchQueue(label: "InternetMonitor"))
 }
 
}
