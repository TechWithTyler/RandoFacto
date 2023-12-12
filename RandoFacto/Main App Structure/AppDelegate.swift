//
//  AppDelegate.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/13/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

#if os(macOS) 
import Cocoa

// Unlike in AppKit or UIKit apps, the app delegate in SwiftUI App-based apps isn't the main entry point. The main App struct is instead, and it has a property for the AppDelegate.
class AppDelegate: NSObject, NSApplicationDelegate {

	// MARK: - macOS App Delegate - Quit When Last Window Closed

	// SwiftUI doesn't yet have a way to prevent closing a macOS app's last window from quitting the app, so we use an app delegate for that.
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}

}
#endif
