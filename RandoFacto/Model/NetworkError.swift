//
//  NetworkError.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

enum NetworkError: LocalizedError {

	// MARK: - Error Case Definitions

	case unknown(reason: String)

	case noInternet

	case noText

	case dataError

	case quotaExceeded

	case userDeletionFailed(reason: String)

	// MARK: - Error Description

	var errorDescription: String? {
		switch self {
			case .noInternet:
				return "No internet connection. Running in offline mode."
			case .noText:
				return "Generated fact doesn't appear to contain text."
			case .dataError:
				return "Fact data error."
			case .quotaExceeded:
				return "Too many favorite facts database requests at once. Try again later."
			case let .userDeletionFailed(reason):
				return "User deletion failed: \(reason)"
			case let .unknown(reason):
				return reason
		}
	}

}
