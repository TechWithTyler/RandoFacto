//
//  NetworkError.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//

import Foundation

enum NetworkError: LocalizedError {

	case unknown(reason: String)

	case noInternet

	case noText

	case dataError

	case filteredDataError

	case registrationFailed

	case logInFailed

	case userDeletionFailed(reason: String)

	var errorDescription: String? {
		switch self {
			case .noInternet:
				return "No internet connection."
			case .noText:
				return "Generated fact doesn't appear to contain text."
			case .dataError, .filteredDataError:
				return "Fact data error."
			case .logInFailed:
				return "Login failed."
			case .registrationFailed:
				return "User registration failed."
			case let .userDeletionFailed(reason):
				return "User deletion failed: \(reason)"
			case let .unknown(reason):
				return reason
		}
	}

}
