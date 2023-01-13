//
//  RandoFactoApp.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//

import SwiftUI
import Firebase

@main
struct RandoFactoApp: App {

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
