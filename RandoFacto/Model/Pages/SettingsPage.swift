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
    
    case display
    
    case account
    
    case advanced
    
    #if(DEBUG)
    case developer
    #endif

}
