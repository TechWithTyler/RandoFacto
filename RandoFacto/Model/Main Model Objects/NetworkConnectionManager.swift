//
//  NetworkConnectionManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/7/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import Network
import Firebase

// Handles network connection.
class NetworkConnectionManager: ObservableObject {
    
    // MARK: - Properties - Network Path Monitor
    
    // Observes changes to the device's network connection to tell the app whether it should run in online or offline mode.
    var networkPathMonitor = NWPathMonitor()
    
    // Whether the device is online.
    @Published var deviceIsOnline: Bool = false
    
    var errorManager: ErrorManager
    
    var firestore: Firestore
    
    init(errorManager: ErrorManager, firestore: Firestore) {
        self.errorManager = errorManager
        self.firestore = firestore
        configureNetworkPathMonitor()
    }
    
    // MARK: - Network - Path Monitor Configuration
    
    // This method configures the network path monitor's path update handler, which tells the app to enable or disable online mode, showing or hiding internet-connection-required UI based on network connection.
    func configureNetworkPathMonitor() {
        // 1. Configure the network path monitor's path update handler.
        networkPathMonitor.pathUpdateHandler = {
            path in
            if path.status == .satisfied {
                // 2. If the path status is satisfied, the device is online, so enable online mode.
                self.goOnline()
            } else {
                // 3. Otherwise, the device is offline, so enable offline mode.
                self.goOffline()
            }
        }
        // 4. Start the network path monitor, using a separate DispatchQueue for it.
        let dispatchQueue = DispatchQueue(label: "Network Path Monitor", qos: .utility)
        networkPathMonitor.start(queue: dispatchQueue)
    }
    
    // MARK: - Network - Online
    
    // This method enables online mode.
    func goOnline() {
        // 1. Try to enable Firestore's network features.
        firestore.enableNetwork { error in
            // 2. If that fails, log an error.
            if let error = error {
                DispatchQueue.main.async {
                    self.errorManager.showError(error)
                }
            } else {
                // 3. If successful, tell the app that the device is online.
                // Updating a published property must be done on the main thread, so we use DispatchQueue.main.async to run any code that sets such properties.
                DispatchQueue.main.async {
                    self.deviceIsOnline = true
                }
            }
        }
    }
    
    // MARK: - Network - Offline
    
    // This method enables offline mode.
    func goOffline() {
        // 1. Try to disable Firestore's network features.
        firestore.disableNetwork {
            error in
            // 2. If that fails, log an error.
            if let error = error {
                DispatchQueue.main.async {
                    self.errorManager.showError(error)
                }
            } else {
                // 3. If successful, tell the app that the device is offline.
                DispatchQueue.main.async {
                    self.deviceIsOnline = false
                }
            }
        }
    }
    
}
