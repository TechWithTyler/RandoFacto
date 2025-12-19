//
//  RandoFactoApp.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import Firebase
import SheftAppsStylishUI

@main
// This is the simplest way to create an app in SwiftUI--you get a fully-functional app just with this one struct!
struct RandoFactoApp: App {

	// MARK: - Properties - macOS AppDelegate Adaptor

	#if os(macOS)
	// Sometimes you still need to use an app delegate in SwiftUI App-based apps. Here, we use the @NSApplicationDelegateAdaptor property wrapper with the AppDelegate class as an argument to supply an app delegate on macOS. In this app, it's used to quit the app when closing the last open window.
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	#endif
    
    // MARK: - Properties - Firebase
    
    // Firebase objects are declared here without their initial values, because they can't be assigned prior to calling FirebaseApp.configure(options:). These are both done in init().

    // The app's Firestore database.
    var firestore: Firestore
    
    // Handles Firebase authentication/user-related tasks.
    var firebaseAuthentication: Authentication
    
    // MARK: - Shared Services
    
    // Services that can be shared across windows (stateless or externally synchronized).
    let networkConnectionManager: NetworkConnectionManager

    let authenticationManager: AuthenticationManager

    let favoriteFactsDatabase: FavoriteFactsDatabase

    // MARK: - Initialization

    // This initializer configures Firebase and all the model objects for this app.
    init() {
        // 1. Configure Firebase.
        RandoFactoApp.setupFirebaseConfiguration()
        // Firebase objects are initialized using Thing.thing(), with Thing being the class name and thing() being the same-name-but-lowercase singleton initializer method. Firebase objects can be initialized only once, and simply using Thing() won't compile.
        let firestore = Firestore.firestore()
        // To make the Firebase authentication object, Auth, easier to understand, we use a custom type alias called Authentication.
        let firebaseAuthentication = Authentication.auth()
        // 2. Create a FirestoreSettings object.
        let firestoreSettings = FirestoreSettings()
        // 3. Enable syncing Firestore data to the device for use offline. Cached Firestore data is stored in the Application Support folder in the app's container.
        // Persistent cache must be at least 1,048,576 bytes/1024KB/1MB. Here we use unlimited storage.
        let persistentCacheSizeBytes = FirestoreCacheSizeUnlimited as NSNumber
        let persistentCache = PersistentCacheSettings(sizeBytes: persistentCacheSizeBytes)
        firestoreSettings.cacheSettings = persistentCache
        // 4. Enable SSL and set the DispatchQueue to the main queue, then set the configured FirestoreSettings object as Firestore's settings.
        firestoreSettings.isSSLEnabled = true
        firestoreSettings.dispatchQueue = .main
        firestore.settings = firestoreSettings
        // 5. Configure the shared services after having set Firestore's settings (you must set all desired Firestore settings BEFORE calling any other methods on the Firestore object).
        let networkConnectionManager = NetworkConnectionManager(firestore: firestore)
        let authenticationManager = AuthenticationManager(firebaseAuthentication: firebaseAuthentication, networkConnectionManager: networkConnectionManager)
        let favoriteFactsDatabase = FavoriteFactsDatabase(firestore: firestore, networkConnectionManager: networkConnectionManager)
        self.firebaseAuthentication = firebaseAuthentication
        self.authenticationManager = authenticationManager
        self.firestore = firestore
        self.favoriteFactsDatabase = favoriteFactsDatabase
        self.networkConnectionManager = networkConnectionManager
        // 6. Link the FavoriteFactsDatabase and AuthenticationManager to each other. This can't be done at initialization time, so these properties are optional, allowing them to be nil until after initialization, where they're then set to their proper values here.
        self.favoriteFactsDatabase.authenticationManager = authenticationManager
        self.authenticationManager.favoriteFactsDatabase = favoriteFactsDatabase
    }

	// MARK: - Windows and Views

	// The windows and views in the app.
    var body: some Scene {
        // Main window scene
        WindowGroup {
            // Per-window objects
            let speechManager = SpeechManager()
            let errorManager = ErrorManager()
            let favoriteFactsDisplayManager = FavoriteFactsDisplayManager(favoriteFactsDatabase: favoriteFactsDatabase)
            let windowStateManager = WindowStateManager(speechManager: speechManager, errorManager: errorManager, favoriteFactsDatabase: favoriteFactsDatabase, favoriteFactsDisplayManager: favoriteFactsDisplayManager, authenticationManager: authenticationManager)
            let authenticationDialogManager = AuthenticationDialogManager(authenticationManager: authenticationManager, errorManager: errorManager)
            let settingsManager = SettingsManager(favoriteFactsDisplayManager: favoriteFactsDisplayManager, authenticationManager: authenticationManager, errorManager: errorManager, speechManager: speechManager)
            ContentView()
                .ignoresSafeArea(edges: .all)
                .environmentObject(networkConnectionManager)
                .environmentObject(favoriteFactsDatabase)
                .environmentObject(authenticationManager)
                .environmentObject(windowStateManager)
                .environmentObject(settingsManager)
                .environmentObject(speechManager)
                .environmentObject(authenticationDialogManager)
                .environmentObject(favoriteFactsDisplayManager)
                .environmentObject(errorManager)
        }
        .commands {
            RandoFactoCommands(networkConnectionManager: networkConnectionManager, authenticationManager: authenticationManager, favoriteFactsDatabase: favoriteFactsDatabase)
        }
        #if os(macOS)
        // Settings window scene
        // On macOS, Settings are presented as a window instead of as one of the app's pages.
        Settings {
            let speechManager = SpeechManager()
            let errorManager = ErrorManager()
            let favoriteFactsDisplayManager = FavoriteFactsDisplayManager(favoriteFactsDatabase: favoriteFactsDatabase)
            let authenticationDialogManager = AuthenticationDialogManager(authenticationManager: authenticationManager, errorManager: errorManager)
            let settingsManager = SettingsManager(favoriteFactsDisplayManager: favoriteFactsDisplayManager, authenticationManager: authenticationManager, errorManager: errorManager, speechManager: speechManager)
			SettingsView()
                .environmentObject(networkConnectionManager)
                .environmentObject(favoriteFactsDatabase)
                .environmentObject(authenticationManager)
                .environmentObject(settingsManager)
                .environmentObject(speechManager)
                .environmentObject(authenticationDialogManager)
                .environmentObject(favoriteFactsDisplayManager)
                .environmentObject(errorManager)
		}
		#endif
	}

    // This method sets up the app's Firebase configuration.
    static func setupFirebaseConfiguration() {
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
        // Create a separate Swift file to hold a constant called firebaseAPIKey, and include its path in your git repository's .gitignore file to make sure it doesn't get committed. We set up the API key here, instead of in GoogleService-Info.plist, so anyone looking at that file in the app bundle's Contents/Resources directory on macOS won't be able to see the API key. This isn't absolutely necessary for Firebase API keys since they're intentionally non-secret, but this prevents tools like GitGuardian from flagging it.
        // Firebase API keys must start with "AIza". The rest of the API key is random.
        options.apiKey = firebaseAPIKey
        // 3. Initialize Firebase with the custom options. This must be done before the Firestore and Auth objects can be initialized.
        // Since we declare the API key outside GoogleService-Info.plist, we need to use configure(options:) instead of configure().
        FirebaseApp.configure(options: options)
    }

}
