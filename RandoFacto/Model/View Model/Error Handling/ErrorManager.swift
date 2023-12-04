//
//  ErrorManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/3/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation
import Firebase

class ErrorManager: ObservableObject {
    
    @Published var authenticationManager: AuthenticationManager?
    
    // MARK: - Properties - RandoFacto Error
    
    // The error to show to the user as an alert or in the authentication dialog.
    @Published var errorToShow: RandoFactoError?
    
    // MARK: - Properties - Booleans
    
    // Whether an error alert should be displayed.
    @Published var showingErrorAlert: Bool = false
    
    init(authenticationManager: AuthenticationManager? = nil) {
        self.authenticationManager = authenticationManager
    }
    
    // MARK: - Error Handling
    
    // This method shows error's localizedDescription as an alert or in the authentication form.
    func showError(_ error: Error) {
        DispatchQueue.main.async {
            // 1. Convert the error to NSError and print it.
            let nsError = error as NSError
            #if DEBUG
            // If an unfamiliar error appears, check its code in the console and add a friendlier message if necessary.
            print("Error: \(nsError)")
            #endif
            // 2. Check the error code to choose which error to show.
            switch nsError.code {
                // Network errors
            case URLError.notConnectedToInternet.rawValue:
                self.errorToShow = .noInternetFactGeneration
            case AuthErrorCode.networkError.rawValue:
                self.errorToShow = .noInternetAuthentication
            case URLError.networkConnectionLost.rawValue:
                self.errorToShow = .networkConnectionLost
            case URLError.timedOut.rawValue:
                self.errorToShow = .factGenerationTimedOut
                // Fact data errors
            case 33000...33999: /*HTTP response code + 33000 to add 33 (FD) to the beginning*/
                self.errorToShow = .badHTTPResponse(domain: nsError.domain)
            case FactGenerator.ErrorCode.noText.rawValue:
                self.errorToShow = .noFactText
            case FactGenerator.ErrorCode.failedToGetData.rawValue:
                self.errorToShow = .factDataError
                // Database errors
            case FirestoreErrorCode.unavailable.rawValue:
                self.errorToShow = .randoFactoDatabaseServerDataRetrievalError
            case AuthErrorCode.userNotFound.rawValue:
                self.errorToShow = .invalidAccount
            case AuthErrorCode.wrongPassword.rawValue:
                self.errorToShow = .incorrectPassword
            case AuthErrorCode.invalidEmail.rawValue:
                self.errorToShow = .invalidEmailFormat
            case AuthErrorCode.requiresRecentLogin.rawValue:
                self.authenticationManager?.logoutCurrentUser()
                self.authenticationManager?.authenticationFormType = nil
                self.errorToShow = .tooLongSinceLastLogin
            case AuthErrorCode.quotaExceeded.rawValue:
                self.errorToShow = .randoFactoDatabaseQuotaExceeded
            default:
                // Other errors
                // If we get an error that hasn't been customized with a friendly message, log the localized description as is.
                let reason = nsError.localizedDescription
                self.errorToShow = .unknown(reason: reason)
            }
            // 3. Show the error in the login/signup dialog if they're open, otherwise show it as an alert.
            if self.authenticationManager?.authenticationFormType != nil {
                self.authenticationManager?.authenticationErrorText = self.errorToShow?.errorDescription
            } else {
                self.showingErrorAlert = true
            }
        }
    }
    
}
