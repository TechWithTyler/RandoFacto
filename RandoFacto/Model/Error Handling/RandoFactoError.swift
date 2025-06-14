//
//  RandoFactoError.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import Foundation

// Errors produced by the app.
enum RandoFactoError: LocalizedError, Equatable, Identifiable {
    
    // MARK: - Error Case Definitions - Network/Internet Connection

    // No internet connection.
    case noInternetFactGeneration, noInternetAuthentication
    
    // Network connection lost.
    case networkConnectionLost

    // An SSL connection couldn't be made (e.g. internet is restricted or not available on the current network).
    case secureConnectionFailed

    // MARK: - Error Case Definitions - Fact Generation

    // The fact generation URL wasn't found.
    case factGeneratorURLNotFound

    // Fact generation/screening timed out.
    case factGenerationTimedOut
    
    // Bad HTTP response, with the given error domain.
    case badHTTPResponse(domain: String)
    
    // Generated fact doesn't contain text.
    case noFactText
    
    // Fact generation/screening error.
    case factDataError
    
    // MARK: - Error Case Definitions - Favorite Facts Database/Authentication
    
    // Too many favorite facts database requests.
    case favoriteFactsDatabaseQuotaExceeded
    
    // Favorite fact no longer exists.
    case favoriteFactNoLongerExists

    // Couldn't get data from server.
    case favoriteFactsDatabaseServerDataRetrievalError
    
    // A login to an invalid/missing account was attempted.
    case attemptToLoginToInvalidAccount
    
    // The password is incorrect.
    case incorrectPassword

    // The password is less than 6 characters long (too weak).
    case passwordTooShort

    // The email address wasn't in the format email@example.xyz.
    case invalidEmailFormat
    
    // Password change or account deletion failed due to the user having logged into this device more than 5 minutes ago.
    case tooLongSinceLastLogin
    
    // MARK: - Error Case Definitions - Unknown
    
    // Unknown error, with the given reason.
    case unknown(reason: String)
    
    // MARK: - Error Description
    
    // The description of the error to show in the error alert or authentication dialog.
    var errorDescription: String? {
        return chooseErrorDescriptionToLog()
    }
    
    // The ID of the error, which allows the error sound/haptics to be triggered when showing the error even if the same error is already displayed.
    var id: UUID {
        return UUID()
    }
    
    // This method chooses the error's description based on the error. Most of these errors already have messages provided, usually by their localized descriptions, but they're usually not user-friendly. This method returns a friendlier message based on which error case was chosen.
    func chooseErrorDescriptionToLog() -> String? {
        switch self {
        case .noInternetFactGeneration:
            return "No internet connection. Running in offline mode."
        case .noInternetAuthentication:
            return "Please check your internet connection and try again."
        case .networkConnectionLost:
            return "Internet connection lost."
        case .secureConnectionFailed:
            return "Secure connection failed. If using a public Wi-Fi network, make sure you've activated your internet access."
        case .factGeneratorURLNotFound:
            return "Unable to access the fact generator URL. Your network may have restricted or no internet access."
        case .factGenerationTimedOut:
            return "Fact generation took too long. Please try again later."
        case let .badHTTPResponse(domain):
            return domain
        case .noFactText:
            return "Generated fact doesn't appear to contain text."
        case .factDataError:
            return "Failed to retrieve or decode fact data."
        case .favoriteFactsDatabaseQuotaExceeded:
            return "Too many favorite fact database requests at once. Please try again later."
        case .favoriteFactsDatabaseServerDataRetrievalError:
            return "Failed to download data from server."
        case .favoriteFactNoLongerExists:
            return "The favorite fact to be deleted no longer exists."
        case .attemptToLoginToInvalidAccount:
            return "There is no account with that email address."
        case .invalidEmailFormat:
            return "The email address must be in the format email@example.xyz."
        case .incorrectPassword:
            return "Incorrect password. If you forgot your password, clear the password field and press \"\(forgotPasswordButtonTitle)\"."
        case .passwordTooShort:
            return "Your password must be at least 6 characters long."
        case .tooLongSinceLastLogin:
            return "It's been more than 5 minutes since you last logged in on this device. Please re-login and try the operation again."
            // This can be written as either case .name(let propertyName) or case let .name(propertyName).
        case .unknown(let reason):
            return reason
        }
    }
    
}
