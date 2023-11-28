//
//  RandoFactoError.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

enum RandoFactoError: LocalizedError, Equatable {

    // MARK: - Error Case Definitions - Internet Connection
    
    // No internet connection.
    case noInternet

    // Network connection lost.
    case networkConnectionLost
    
    // MARK: - Error Case Definitions - Fact Generation

	// Bad HTTP response, with the given error domain.
	case badHTTPResponse(domain: String)

	// Generated fact doesn't contain text.
	case noFactText

	// Fact generation/screening error.
	case factDataError

	// MARK: - Error Case Definitions - RandoFacto Database

	// Too many RandoFacto database requests (e.g. repeatedly favoriting and unfavoriting the same fact).
	case randoFactoDatabaseQuotaExceeded

	// Couldn't get data from server.
	case randoFactoDatabaseServerDataRetrievalError

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

	// This method chooses the error's description based on the error.
	func chooseErrorDescriptionToLog() -> String? {
		switch self {
			case .noInternet:
				return "No internet connection. Running in offline mode."
			case .networkConnectionLost:
				return "Internet connection lost."
			case let .badHTTPResponse(domain):
				return domain
			case .noFactText:
				return "Generated fact doesn't appear to contain text."
			case .factDataError:
				return "Failed to retrieve or decode fact data."
			case .randoFactoDatabaseQuotaExceeded:
				return "Too many favorite fact database requests at once. Try again later."
			case .randoFactoDatabaseServerDataRetrievalError:
				return "Failed to download data from server. Using device data."
			case .tooLongSinceLastLogin:
				return "It's been too long since you last logged in on this device. Please re-login and try the operation again."
            // This can be written as either case .name(let propertyName) or case let .name(propertyName).
			case .unknown(let reason):
				return reason
		}
	}

}
