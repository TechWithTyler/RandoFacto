//
//  ErrorManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/5/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ErrorManager: ObservableObject {
    
    // Whether an error alert should be/is being displayed.
    @Published var showingErrorAlert: Bool = false
    
    // MARK: - Properties - RandoFacto Error
    
    // The error to show to the user as an alert or in the authentication dialog.
    @Published var errorToShow: RandoFactoError? = nil
    
    // MARK: - Error Handling
    
    // This method shows error's localizedDescription as an alert or in the authentication form.
    func showError(_ error: Error, completionHandler: ((RandoFactoError) -> Void)? = nil) {
        // 1. Convert the error to NSError, and print it in internal builds.
        let nsError = error as NSError
#if DEBUG
        // If an unfamiliar error appears, check its code in the console and add a friendlier message if necessary.
        print("Error: \(nsError)")
#endif
        // 2. Check the error code to choose which error to show.
        switch nsError.code {
            // Network errors
        case URLError.notConnectedToInternet.rawValue:
            errorToShow = .noInternetFactGeneration
        case URLError.secureConnectionFailed.rawValue:
            errorToShow = .secureConnectionFailed
        case AuthErrorCode.networkError.rawValue:
            errorToShow = .noInternetAuthentication
        case URLError.networkConnectionLost.rawValue:
            errorToShow = .networkConnectionLost
        case URLError.timedOut.rawValue:
            errorToShow = .factGenerationTimedOut
        case URLError.cannotFindHost.rawValue:
            errorToShow = .factGeneratorURLNotFound
            // Fact data errors
        case FactGenerator.ErrorCode.factDataHTTPResponseCodeRange: /*HTTP response code + 33000 to add 33 (FD) to the beginning*/
            errorToShow = .badHTTPResponse(domain: nsError.domain)
        case FactGenerator.ErrorCode.noText.rawValue:
            errorToShow = .noFactText
        case FactGenerator.ErrorCode.failedToGetData.rawValue:
            errorToShow = .factDataError
            // Favorite facts database errors
        case FirestoreErrorCode.unavailable.rawValue:
            errorToShow = .favoriteFactsDatabaseServerDataRetrievalError
        case FavoriteFactsDatabase.ErrorCode.favoriteFactReferenceNotFound.rawValue:
            errorToShow = .favoriteFactNoLongerExists
        case AuthErrorCode.userNotFound.rawValue:
            errorToShow = .attemptToLoginToInvalidAccount
        case AuthErrorCode.wrongPassword.rawValue:
            errorToShow = .incorrectPassword
        case AuthErrorCode.weakPassword.rawValue:
            errorToShow = .passwordTooShort
        case AuthErrorCode.invalidEmail.rawValue:
            errorToShow = .invalidEmailFormat
        case AuthErrorCode.requiresRecentLogin.rawValue:
            errorToShow = .tooLongSinceLastLogin
        case AuthErrorCode.quotaExceeded.rawValue:
            errorToShow = .favoriteFactsDatabaseQuotaExceeded
        default:
            // Other errors
            // If we get an error that hasn't been customized with a friendly message, log the localized description as is. Only errors with messages that aren't understandable by the average user are customized above.
            let reason = nsError.localizedDescription
            errorToShow = .unknown(reason: reason)
        }
        // 3. Show the error in the authentication dialog if it's open, otherwise show it as an alert.
        if let completionHandler = completionHandler, let errorToShow = errorToShow {
            completionHandler(errorToShow)
        } else {
            showingErrorAlert = true
        }
    }
    
}
