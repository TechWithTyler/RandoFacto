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
		FirebaseApp.configure()
	}

    var body: some Scene {
        WindowGroup {
            ContentView()
				.frame(minWidth: 400, minHeight: 300, alignment: .center)
		}
    }

}
