//
//  RandoFactoApp.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//

import SwiftUI

@main
struct RandoFactoApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
				.environment(\.backgroundMaterial, .ultraThick)
				.frame(minWidth: 400, minHeight: 300, alignment: .center)
		}
    }

}
