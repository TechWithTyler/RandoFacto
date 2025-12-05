//
//  UserDefaultsKeyNames.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/4/25.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import Foundation

extension UserDefaults {

    struct KeyNames {

        // MARK: - UserDefaults Key Names

        static let factTextSize: String = "factTextSize"

        static let selectedSettingsPage: String = "selectedSettingsPage"

        static let selectedVoiceID: String = "selectedVoiceID"

        static let initialFact: String = "initialFact"

        static let favoriteFactsRandomizerEffect: String = "favoriteFactsRandomizerEffect"

        static let skipFavoritesOnFactGeneration: String = "skipFavoritesOnFactGeneration"

        static let sortFavoriteFactsAscending: String = "sortFavoriteFactsAscending"

        static let shouldOnboard: String = "shouldOnboard"

        static let urlRequestTimeoutInterval: String = "urlRequestTimeoutInterval"

    }

}
