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

	@ObservedObject var viewModel = RandoFactoViewModel()

	// MARK: - Windows and Views

    var body: some Scene {
        WindowGroup {
			ContentView(viewModel: viewModel)
				.frame(minWidth: 400, minHeight: 300, alignment: .center)
				.ignoresSafeArea(edges: .all)
		}
		#if os(macOS)
		.windowStyle(.hiddenTitleBar)
		#endif
	}

}
