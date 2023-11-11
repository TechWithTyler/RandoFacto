//
//  RandoFactoApp.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI
import Firebase

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {

	// MARK: - Quit When Last Window Closed

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}

}
#endif

@main
struct RandoFactoApp: App {

	// MARK: - macOS AppDelegate Adaptor

	#if os(macOS)
	// Sometimes you still need to use an app delegate in SwiftUI App-based apps. Here, we use the @NSApplicationDelegateAdaptor property wrapper with the AppDelegate class as an argument to supply an app delegate on macOS.
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	#endif

	@ObservedObject var viewModel: RandoFactoViewModel

	// MARK: - Windows and Views

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
		settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
		firestore.settings = settings
		// 5. Configure the RandoFacto view model.
		viewModel = RandoFactoViewModel()
	}

    var body: some Scene {
        WindowGroup {
			ContentView(viewModel: viewModel)
				.frame(minWidth: 400, minHeight: 300, alignment: .center)
				.ignoresSafeArea(edges: .all)
		}
		#if os(macOS)
		Settings {
			SettingsView(viewModel: viewModel)
				.frame(width: 400, height: 400)
		}
		#endif
	}

}
