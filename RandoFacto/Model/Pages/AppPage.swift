//
//  AppPage.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import Foundation

// A page in the app.
// CaseIterable allows you to iterate through an enum's caaes as if it were a collection. Getting the rawValue String of a case without an explicit raw value returns the case name converted from camelCase to all lowercase. When displaying page names, we want them in title-case, so the rawValue is capitalized anywhere it's displayed.
enum AppPage : String, CaseIterable {

	case randomFact

	case favoriteFacts

    #if !os(macOS)
    // Don't include Settings as a page on macOS--it's accessed via the Settings option in the app menu.
	case settings
    #endif
    
}
