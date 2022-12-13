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

	init() {
		configureFirebase()
	}

    var body: some Scene {
        WindowGroup {
            ContentView()
				.frame(minWidth: 400, minHeight: 300, alignment: .center)
		}
    }

	func configureFirebase() {
		FirebaseApp.configure()
		let settings = FirestoreSettings()
		settings.isPersistenceEnabled = true
		// Enable offline data persistence
		let firestore = Firestore.firestore()
		firestore.settings = settings
	}

}
