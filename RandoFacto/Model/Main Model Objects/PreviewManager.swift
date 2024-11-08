//
//  PreviewManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/1/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

#if(DEBUG)
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

    init(prepBlock: ((AppStateManager, ErrorManager, NetworkConnectionManager, FavoriteFactsDatabase, AuthenticationManager, FavoriteFactsListDisplayManager) -> Void)? = nil) {
        let errorManager = ErrorManager()
        let firestore = Firestore.firestore()
        let firebaseAuthentication = Authentication.auth()
        let networkConnectionManager = NetworkConnectionManager(errorManager: errorManager, firestore: firestore)
        let authenticationManager = AuthenticationManager(firebaseAuthentication: firebaseAuthentication, networkConnectionManager: networkConnectionManager, errorManager: errorManager)
        let favoriteFactsDatabase = FavoriteFactsDatabase(firestore: firestore, networkConnectionManager: networkConnectionManager, errorManager: errorManager)
        let favoriteFactsListDisplayManager = FavoriteFactsListDisplayManager(favoriteFactsDatabase: favoriteFactsDatabase)
        let appStateManager = AppStateManager(errorManager: errorManager, favoriteFactsDatabase: favoriteFactsDatabase, favoriteFactsListDisplayManager: favoriteFactsListDisplayManager, authenticationManager: authenticationManager)
        prepBlock?(appStateManager, errorManager, networkConnectionManager, favoriteFactsDatabase, authenticationManager, favoriteFactsListDisplayManager)
        self.appStateManager = appStateManager
        self.errorManager = errorManager
        self.networkConnectionManager = networkConnectionManager
        self.favoriteFactsListDisplayManager = favoriteFactsListDisplayManager
        self.favoriteFactsDatabase = favoriteFactsDatabase
        self.authenticationManager = authenticationManager
        self.favoriteFactsDatabase.authenticationManager = authenticationManager
        self.authenticationManager.favoriteFactsDatabase = favoriteFactsDatabase
    }

}
#endif
