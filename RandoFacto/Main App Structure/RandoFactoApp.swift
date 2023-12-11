//
//  RandoFactoApp.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase
import SheftAppsStylishUI

@main
// This is the simplest way to create an app in SwiftUI--you get a fully-functional app just with this one struct!
struct RandoFactoApp: App {

	// MARK: - macOS AppDelegate Adaptor

	#if os(macOS)
	// Sometimes you still need to use an app delegate in SwiftUI App-based apps. Here, we use the @NSApplicationDelegateAdaptor property wrapper with the AppDelegate class as an argument to supply an app delegate on macOS.
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	#endif

    var firestore: Firestore
    
    var firebaseAuthentication: Authentication
    
    // MARK: - Properties - Model Objects
    
    // Manages the app state (e.g. the fact to display, the page to display, the Settings page to display on macOS).
	@ObservedObject var appStateManager: AppStateManager
    
    // Manages the app's network features.
    @ObservedObject var networkManager: NetworkManager
    
    // Manages authentication/user accounts.
    @ObservedObject var authenticationManager: AuthenticationManager
    
    // The favorite facts database.
    @ObservedObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    // Handles errors.
    @ObservedObject var errorManager: ErrorManager
    
    // Handles searching and sorting of favorite facts.
    @ObservedObject var favoriteFactSearcher: FavoriteFactSearcher
    
    var windowTitle: String {
        var appName = (Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String)!
        #if DEBUG && os(macOS)
        appName.appendSheftAppsTeamInternalBuildDesignation()
        #endif
        return appName
    }

	// MARK: - Windows and Views

	// The windows and views in the app.
    var body: some Scene {
        WindowGroup {
			ContentView()
                .environmentObject(appStateManager)
                .environmentObject(networkManager)
                .environmentObject(errorManager)
                .environmentObject(favoriteFactsDatabase)
                .environmentObject(authenticationManager)
                .environmentObject(favoriteFactSearcher)
            #if os(macOS)
				.frame(minWidth: 800, minHeight: 300, alignment: .center)
            #endif
				.ignoresSafeArea(edges: .all)
		}
        .commands {
            RandoFactoCommands(appStateManager: appStateManager, networkManager: networkManager, errorManager: errorManager, authenticationManager: authenticationManager, favoriteFactsDatabase: favoriteFactsDatabase)
        }
        #if os(macOS)
        // On macOS, Settings are presented as a window instead of as one of the app's pages.
		Settings {
			SettingsView()
                .environmentObject(appStateManager)
                .environmentObject(networkManager)
                .environmentObject(errorManager)
                .environmentObject(favoriteFactsDatabase)
                .environmentObject(authenticationManager)
		}
		#endif
	}

	// MARK: - Initiailization

    // This initializer configures Firebase and all the model objects for this app.
	init() {
		// 1. Make sure the GoogleService-Info.plist file is present in the app bundle.
        let firebaseConfigurationFilename = "GoogleService-Info"
        let firebaseConfigurationFileExtension = "plist"
        guard let googleServicePlist = Bundle.main.url(forResource: firebaseConfigurationFilename, withExtension: firebaseConfigurationFileExtension) else {
            fatalError("Firebase configuration file \(firebaseConfigurationFilename).\(firebaseConfigurationFileExtension) not found in app bundle.")
        }
        let firebaseConfigurationFilePath = googleServicePlist.path
        // 2. Create a FirebaseOptions object with the API key.
        guard let options = FirebaseOptions(contentsOfFile: firebaseConfigurationFilePath) else {
            fatalError("Failed to load options from Firebase configuration file \(firebaseConfigurationFilename).\(firebaseConfigurationFileExtension).")
        }
        // Create a separate Swift file to hold a constant called firebaseAPIKey, and include its path in your git repository's .gitignore file to make sure it doesn't get committed. We set up the API key here, instead of in GoogleService-Info.plist, so anyone looking at that file in the app bundle's Contents/Resources directory on macOS won't be able to see the API key.
        options.apiKey = firebaseAPIKey
        // 3. Initialize Firebase with the custom options.
        // Since we declare the API key outside GoogleService-Info.plist, we need to pass a set of custom options to the configure() method.
        FirebaseApp.configure(options: options)
        // Creation of the main Firebase objects is written as Thing.thing() for some reason.
        let firestore = Firestore.firestore()
        // To make the Firebase authentication object, Auth, easier to understand, we use a custom type alias called Authentication.
        let firebaseAuthentication = Authentication.auth()
        // 4. Enable syncing Firestore data to the device for use offline.
        let settings = FirestoreSettings()
        // Persistent cache must be at least 1,048,576 bytes/1024KB/1MB. Here we use unlimited storage.
        let persistentCacheSizeBytes = FirestoreCacheSizeUnlimited as NSNumber
        let persistentCache = PersistentCacheSettings(sizeBytes: persistentCacheSizeBytes)
        settings.cacheSettings = persistentCache
        settings.isSSLEnabled = true
        settings.dispatchQueue = .main
        firestore.settings = settings
        // 5. Configure the managers after having set Firestore's settings (you must set all desired Firestore settings BEFORE calling any other methods on it).
        let errorManager = ErrorManager()
        let networkManager = NetworkManager(errorManager: errorManager, firestore: firestore)
        let favoriteFactSearcher = FavoriteFactSearcher()
        let authenticationManager = AuthenticationManager(firebaseAuthentication: firebaseAuthentication, networkManager: networkManager, errorManager: errorManager)
        let favoriteFactsDatabase = FavoriteFactsDatabase(firestore: firestore, networkManager: networkManager, errorManager: errorManager, favoriteFactSearcher: favoriteFactSearcher)
        self.firebaseAuthentication = firebaseAuthentication
        self.authenticationManager = authenticationManager
        self.firestore = firestore
        self.favoriteFactsDatabase = favoriteFactsDatabase
        self.errorManager = errorManager
        self.networkManager = NetworkManager(errorManager: errorManager, firestore: firestore)
        self.appStateManager = AppStateManager(errorManager: errorManager, networkManager: networkManager, favoriteFactsDatabase: favoriteFactsDatabase, authenticationManager: authenticationManager)
        self.favoriteFactSearcher = favoriteFactSearcher
        self.favoriteFactsDatabase.authenticationManager = authenticationManager
        self.authenticationManager.favoriteFactsDatabase = favoriteFactsDatabase
	}

}
