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
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	#endif

	// MARK: - Initialization

	init() {
		configureFirebase()
	}

	// MARK: - Windows and Views

    var body: some Scene {
        WindowGroup {
            ContentView()
				.frame(minWidth: 400, minHeight: 300, alignment: .center)
				.ignoresSafeArea(edges: .all)
		}
		#if os(macOS)
		.windowStyle(.hiddenTitleBar)
		#endif
	}

	// MARK: - Firebase Configuration

	func configureFirebase() {
		// 1. Make sure the GoogleService-Info.plist file is present in the app bundle.
		guard let googleServicePlist = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") else {
			fatalError("Firebase configuration file not found")
		}
		// 2. Create a FirebaseAppOptions object with the API key
		guard let options = FirebaseOptions(contentsOfFile: googleServicePlist.path) else {
			fatalError("Failed to load options from configuration file")
		}
		options.apiKey = firebaseApiKey
		// Initialize Firebase with the custom options
		FirebaseApp.configure(options: options)
		let settings = FirestoreSettings()
		let firestore = Firestore.firestore()
		settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
		firestore.settings = settings
	}


}
