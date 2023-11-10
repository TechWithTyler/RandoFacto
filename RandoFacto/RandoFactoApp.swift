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

	@ObservedObject var viewModel: RandoFactoViewModel

	// MARK: - Windows and Views

	init() {
		// 1. Make sure the GoogleService-Info.plist file is present in the app bundle.
		guard let googleServicePlist = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") else {
			fatalError("Firebase configuration file not found")
		}
		// 2. Create a FirebaseOptions object with the API key.
		guard let options = FirebaseOptions(contentsOfFile: googleServicePlist.path) else {
			fatalError("Failed to load options from configuration file")
		}
		options.apiKey = firebaseApiKey
		// 3. Initialize Firebase with the custom options.
		FirebaseApp.configure(options: options)
		let firestore = Firestore.firestore()
		let settings = FirestoreSettings()
		settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
		firestore.settings = settings
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
