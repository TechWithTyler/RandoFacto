//
//  AppDelegate.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/13/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

#if os(macOS)
import Foundation
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

	// MARK: - Quit When Last Window Closed

	// SwiftUI doesn't yet have a way to prevent closing a macOS app's last window from quitting the app, so we use an app delegate for that.
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}

}
#endif
