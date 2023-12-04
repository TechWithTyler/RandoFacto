//
//  NetworkManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/3/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase
import Network

class NetworkManager: ObservableObject {
    
    @Published var favoriteFactsDatabase: FavoriteFactsDatabase?
    
    @Published var errorManager: ErrorManager?
    
    // Whether the device is online.
    @Published var online: Bool = false
    
    // MARK: - Properties - Network Monitor
    
    // Observes changes to the device's network connection to tell the app whether it should run in online or offline mode.
    var networkPathMonitor = NWPathMonitor()
    
    init(favoriteFactsDatabase: FavoriteFactsDatabase? = nil, errorManager: ErrorManager? = nil) {
        self.favoriteFactsDatabase = favoriteFactsDatabase
        self.errorManager = errorManager
    }
    
    // MARK: - Network - Path Monitor Configuration
    
    // This method configures the network path monitor's path update handler, which tells the app to enable or disable online mode, showing or hiding internet-connection-required UI based on network connection.
    func configureNetworkPathMonitor() {
        // 1. Configure the network path monitor's path update handler.
        networkPathMonitor.pathUpdateHandler = {
            [self] path in
            if path.status == .satisfied {
                // 2. If the path status is satisfied, the device is online, so enable online mode.
                goOnline()
            } else {
                // 3. Otherwise, the device is offline, so enable offline mode.
                goOffline()
            }
        }
        // 4. Start the network path monitor, using a separate DispatchQueue for it.
        let dispatchQueue = DispatchQueue(label: "Network Path Monitor")
        networkPathMonitor.start(queue: dispatchQueue)
    }
    
    // MARK: - Network - Online
    
    // This method enables online mode.
    func goOnline() {
        // 1. Try to enable Firestore's network features.
        favoriteFactsDatabase?.firestore.enableNetwork {
            [self] error in
            // 2. If that fails, log an error.
            if let error = error {
                errorManager?.showError(error)
            } else {
                // 3. If successful, tell the app that the device is online.
                // Updating a published property must be done on the main thread, so we use DispatchQueue.main.async to run any code that sets such properties.
                DispatchQueue.main.async { [self] in
                    online = true
                }
            }
        }
    }
    
    // MARK: - Network - Offline
    
    // This method enables offline mode.
    func goOffline() {
        // 1. Try to disable Firestore's network features.
        favoriteFactsDatabase?.firestore.disableNetwork {
            [self] error in
            // 2. If that fails, log an error.
            if let error = error {
                errorManager?.showError(error)
            } else {
                // 3. If successful, tell the app that the device is offline.
                DispatchQueue.main.async { [self] in
                    online = false
                }
            }
        }
    }
    
}
