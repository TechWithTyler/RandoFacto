//
//  PreviewManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/1/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation
import Firebase

// An object that encapsulates all model objects for use in Xcode previews.
class PreviewManager: ObservableObject {

    var appStateManager: AppStateManager

    var errorManager: ErrorManager

    var networkConnectionManager: NetworkConnectionManager

    var favoriteFactsDatabase: FavoriteFactsDatabase

    var authenticationManager: AuthenticationManager

    var favoriteFactsListDisplayManager: FavoriteFactsListDisplayManager

    static var shared: PreviewManager {
        // 1. Create each manager just like in the main app init.
        let errorManager = ErrorManager()
        let firestore = Firestore.firestore()
        let firebaseAuthentication = Authentication.auth()
        let networkConnectionManager = NetworkConnectionManager(errorManager: errorManager, firestore: firestore)
        let authenticationManager = AuthenticationManager(firebaseAuthentication: firebaseAuthentication, networkConnectionManager: networkConnectionManager, errorManager: errorManager)
        let favoriteFactsDatabase = FavoriteFactsDatabase(firestore: firestore, networkConnectionManager: networkConnectionManager, errorManager: errorManager)
        let favoriteFactsListDisplayManager = FavoriteFactsListDisplayManager(favoriteFactsDatabase: favoriteFactsDatabase)
        let appStateManager = AppStateManager(errorManager: errorManager, networkConnectionManager: networkConnectionManager, favoriteFactsDatabase: favoriteFactsDatabase, favoriteFactsListDisplayManager: favoriteFactsListDisplayManager, authenticationManager: authenticationManager)
        // 3. Tell the AppStateManager that this instance is being used for Xcode previews, which will prevent code such as the randomizer timer from running.
        appStateManager.forPreview = true
        // 3. Create the global instance of PreviewManager, with all the app's model objects injected.
        let previewManager = PreviewManager(appStateManager: appStateManager, errorManager: errorManager, networkConnectionManager: networkConnectionManager, favoriteFactsDatabase: favoriteFactsDatabase, authenticationManager: authenticationManager, favoriteFactsListDisplayManager: favoriteFactsListDisplayManager)
        // 4. Perform any desired setup for Xcode previews.
        previewManager.configurePreview()
        // 5. Return the PreviewManager.
        return previewManager
    }

    init(appStateManager: AppStateManager, errorManager: ErrorManager, networkConnectionManager: NetworkConnectionManager, favoriteFactsDatabase: FavoriteFactsDatabase, authenticationManager: AuthenticationManager, favoriteFactsListDisplayManager: FavoriteFactsListDisplayManager) {
        self.appStateManager = appStateManager
        self.errorManager = errorManager
        self.networkConnectionManager = networkConnectionManager
        self.favoriteFactsListDisplayManager = favoriteFactsListDisplayManager
        self.favoriteFactsDatabase = favoriteFactsDatabase
        self.authenticationManager = authenticationManager
        self.favoriteFactsDatabase.authenticationManager = authenticationManager
        self.authenticationManager.favoriteFactsDatabase = favoriteFactsDatabase
    }

    func configurePreview() {
        appStateManager.factText = sampleFact
    }

}
