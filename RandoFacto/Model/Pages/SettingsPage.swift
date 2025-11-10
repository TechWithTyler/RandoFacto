//
//  SettingsPage.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/17/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

// MARK: - Imports

import Foundation

// MARK: - Settings Page Enum

// A page in Settings.
enum SettingsPage : String {

    // MARK: - Settings Page Icons Enum

    enum Icons: String {

        case display = "textformat.size"

        case speech = "speaker.wave.2.bubble.left"

        case account = "person.circle"

        case advanced = "gear"

        #if(DEBUG)
        case developer = "hammer"
        #endif

    }

    // MARK: - Settings Page Enum Cases

    case display

    case speech

    case account
    
    case advanced
    
    #if(DEBUG)
    case developer
    #endif

}
