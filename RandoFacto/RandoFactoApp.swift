//
//  RandoFactoApp.swift
//  RandoFacto
//
//  Created by TechWithTyler on 11/21/22.
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

	// MARK: - AppDelegate Adaptor

	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	// MARK: - Initialization

	init() {
		configureFirebase()
	}

	// MARK: - Windows and Views

    var body: some Scene {
        WindowGroup {
            ContentView()
				.frame(minWidth: 400, minHeight: 300, alignment: .center)
		}
    }

	// MARK: - Firebase Configuration

	func configureFirebase() {
		FirebaseApp.configure()
		let settings = FirestoreSettings()
		let firestore = Firestore.firestore()
		settings.isPersistenceEnabled = true
		settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
		firestore.settings = settings
	}

}
