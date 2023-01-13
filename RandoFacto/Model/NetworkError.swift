//
//  NetworkError.swift
//  RandoFacto
//
//  Created by TechWithTyler on 11/29/22.
//

import Foundation

enum NetworkError: LocalizedError {

	// MARK: - Error Case Definitions

	case unknown(reason: String)

	case noInternet

	case noText

	case dataError

	case filteredDataError

	case userDeletionFailed(reason: String)

	// MARK: - Error Description

	var errorDescription: String? {
		switch self {
			case .noInternet:
				return "No internet connection. Running in offline mode."
			case .noText:
				return "Generated fact doesn't appear to contain text."
			case .dataError, .filteredDataError:
				return "Fact data error."
			case let .userDeletionFailed(reason):
				return "User deletion failed: \(reason)"
			case let .unknown(reason):
				return reason
		}
	}

}
