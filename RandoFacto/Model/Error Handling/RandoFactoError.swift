//
//  RandoFactoError.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

enum RandoFactoError: LocalizedError, Equatable {

	// MARK: - Error Case Definitions - Unknown

	// Unknown error, with the given reason.
	case unknown(reason: String)

	// MARK: - Error Case Definitions - Fact Generation

	// No internet connection.
	case noInternet

	// Network connection lost.
	case networkConnectionLost

	// Bad HTTP response, with the given error domain.
	case badHTTPResponse(domain: String)

	// Generated fact doesn't contain text.
	case noFactText

	// Fact generation/screening error.
	case factDataError

	// MARK: - Error Case Definitions - RandoFacto Database

	// Too many RandoFacto database requests (e.g. repeatedly favoriting and unfavoriting the same fact).
	case randoFactoDatabaseQuotaExceeded

	// Couldn't get data from server
	case randoFactoDatabaseServerDataRetrievalError

	// Account deletion failed, with the given reason.
	case tooLongSinceLastLogin

	// MARK: - Error Description

	var errorDescription: String? {
		return chooseErrorDescriptionToLog()
	}

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
				return "It's been too long since you last logged in on this device. If you're trying to delete your account, please re-login and try again. If you're trying to change your password, please enter your email address and press \"\(forgotPasswordButtonTitle)\" to send a password reset email."
			case let .unknown(reason):
				return reason
		}
	}

	// MARK: - Inequality Check

	// This method compares the UUID of 2 RandoFactoError objects to see if they're not equal.
	static func !=(lError: RandoFactoError, rError: RandoFactoError) -> Bool {
		return lError.id != rError.id
	}

}
