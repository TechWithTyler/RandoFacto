//
//  PreviewManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/1/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

#if(DEBUG)

// MARK: - Imports

import Foundation
import Firebase

// An object that encapsulates all model objects for use in Xcode previews.
class PreviewManager: ObservableObject {

    // MARK: - Type Aliases

    typealias PreviewDataObjects = (WindowStateManager, SettingsManager, SpeechManager, ErrorManager, AuthenticationDialogManager, NetworkConnectionManager, FavoriteFactsDatabase, AuthenticationManager, FavoriteFactsDisplayManager) -> Void

    // MARK: - Properties - Objects

    var windowStateManager: WindowStateManager

    var settingsManager: SettingsManager

    var speechManager: SpeechManager

    var errorManager: ErrorManager

    var authenticationDialogManager: AuthenticationDialogManager

    var networkConnectionManager: NetworkConnectionManager

    var favoriteFactsDatabase: FavoriteFactsDatabase

    var authenticationManager: AuthenticationManager

    var favoriteFactsDisplayManager: FavoriteFactsDisplayManager

    // MARK: - Initialization

    init(prepBlock: PreviewDataObjects? = nil) {
        let speechManager = SpeechManager()
        let errorManager = ErrorManager()
        let firestore = Firestore.firestore()
        let firebaseAuthentication = Authentication.auth()
        let networkConnectionManager = NetworkConnectionManager(firestore: firestore)
        let authenticationManager = AuthenticationManager(firebaseAuthentication: firebaseAuthentication, networkConnectionManager: networkConnectionManager)
        let authenticationDialogManager = AuthenticationDialogManager(authenticationManager: authenticationManager, errorManager: errorManager)
        let favoriteFactsDatabase = FavoriteFactsDatabase(firestore: firestore, networkConnectionManager: networkConnectionManager)
        let favoriteFactsDisplayManager = FavoriteFactsDisplayManager(favoriteFactsDatabase: favoriteFactsDatabase)
        let windowStateManager = WindowStateManager(speechManager: speechManager, errorManager: errorManager, favoriteFactsDatabase: favoriteFactsDatabase, favoriteFactsDisplayManager: favoriteFactsDisplayManager, authenticationManager: authenticationManager)
        let settingsManager = SettingsManager(favoriteFactsDisplayManager: favoriteFactsDisplayManager, authenticationManager: authenticationManager, errorManager: errorManager, speechManager: speechManager)
        prepBlock?(windowStateManager, settingsManager, speechManager, errorManager, authenticationDialogManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsDisplayManager)
        self.windowStateManager = windowStateManager
        self.settingsManager = settingsManager
        self.speechManager = speechManager
        self.errorManager = errorManager
        self.authenticationDialogManager = authenticationDialogManager
        self.networkConnectionManager = networkConnectionManager
        self.favoriteFactsDisplayManager = favoriteFactsDisplayManager
        self.favoriteFactsDatabase = favoriteFactsDatabase
        self.authenticationManager = authenticationManager
        self.favoriteFactsDatabase.authenticationManager = authenticationManager
        self.authenticationManager.favoriteFactsDatabase = favoriteFactsDatabase
    }

}
#endif
