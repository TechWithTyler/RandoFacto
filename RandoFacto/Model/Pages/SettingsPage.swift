//
//  SettingsPage.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/17/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation

// A page in Settings.
enum SettingsPage : String {

    enum Icons: String {

        case display = "textformat.size"

        case account = "person.circle"

        case advanced = "gear"

        case speech = "speaker.wave.2.bubble.left"

        #if(DEBUG)
        case developer = "hammer"
        #endif

    }

    case display

    case speech

    case account
    
    case advanced
    
    #if(DEBUG)
    case developer
    #endif

}
