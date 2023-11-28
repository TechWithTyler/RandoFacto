//
//  RandoFactoApp.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase

@main
// This is the simplest way to create an app in SwiftUI--you get a fully-functional app just with this one struct!
struct RandoFactoApp: App {

	// MARK: - macOS AppDelegate Adaptor

	#if os(macOS)
	// Sometimes you still need to use an app delegate in SwiftUI App-based apps. Here, we use the @NSApplicationDelegateAdaptor property wrapper with the AppDelegate class as an argument to supply an app delegate on macOS.
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	#endif

	// The main model object for the app, which supplies data for its views.
	@ObservedObject var viewModel: RandoFactoManager

	// MARK: - Windows and Views

	// The windows and views in the app.
    var body: some Scene {
        WindowGroup {
			ContentView(viewModel: viewModel)
            #if os(macOS)
				.frame(minWidth: 800, minHeight: 300, alignment: .center)
            #endif
				.ignoresSafeArea(edges: .all)
		}
        .commands {
            RandoFactoCommands(viewModel: viewModel)
        }
        #if os(macOS)
        // On macOS, Settings are presented as a window instead of as one of the app's pages.
		Settings {
			SettingsView(viewModel: viewModel)
		}
		#endif
	}

	// MARK: - Initiailization

	init() {
		// 1. Make sure the GoogleService-Info.plist file is present in the app bundle.
		guard let googleServicePlist = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") else {
			fatalError("Firebase configuration file not found")
		}
		// 2. Create a FirebaseOptions object with the API key.
		guard let options = FirebaseOptions(contentsOfFile: googleServicePlist.path) else {
			fatalError("Failed to load options from Firebase configuration file")
		}
		// Create a separate Swift file to hold a constant called firebaseAPIKey, and include its path in your git repository's .gitignore file to make sure it doesn't get committed. We set up the API key here, instead of in GoogleService-Info.plist, so anyone looking at that file in the app bundle's Contents/Resources directory on macOS won't be able to see the API key.
		options.apiKey = firebaseAPIKey
		// 3. Initialize Firebase with the custom options.
		FirebaseApp.configure(options: options)
		// 4. Enable syncing Firestore data to the device for use offline.
		let firestore = Firestore.firestore()
		let settings = FirestoreSettings()
		// Persistent cache must be at least 1,048,576 bytes (1024KB or 1MB). Here we use unlimited storage.
		let persistentCacheSizeBytes = FirestoreCacheSizeUnlimited as NSNumber
		let persistentCache = PersistentCacheSettings(sizeBytes: persistentCacheSizeBytes)
		settings.cacheSettings = persistentCache
		settings.isSSLEnabled = true
		settings.dispatchQueue = .main
		firestore.settings = settings
		// 5. Configure the RandoFacto view model.
		viewModel = RandoFactoManager()
	}

}
