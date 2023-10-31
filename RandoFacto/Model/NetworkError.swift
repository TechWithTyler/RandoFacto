//
//  NetworkError.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/29/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

enum NetworkError: LocalizedError {

	// MARK: - Error Case Definitions - Unknown

	case unknown(reason: String)

	// MARK: - Error Case Definitions - Fact Generation

	case noInternet

	case httpResponseError(domain: String)

	case noFactText

	case factDataError

	// MARK: - Error Case Definitions - RandoFacto Database

	case randoFactoDatabaseQuotaExceeded

	case userDeletionFailed(reason: String)

	// MARK: - HTTP Response Status Code To Error Domain String

	static func getErrorDomainForHTTPResponseCode(_ code: Int) -> String {
		switch code {
			case 400: return "Bad Request (maybe all our API calls used up for this month)"
			case 401: return "Unauthorized"
			case 403: return "Forbidden (maybe access to this service isn't allowed from your current network)"
			case 404: return "Not Found"
			case 408: return "Request Timeout (maybe bad internet connection)"
			case 500: return "Internal Server Error"
			case 502: return "Bad Gateway"
			case 503: return "Service Unavailable"
			case 504: return "Gateway Timeout"
			case 505: return "HTTP Version Not Supported"
			default: return "Unknown Response Code"
		}
	}

	// MARK: - Error Description

	var errorDescription: String? {
		switch self {
			case .noInternet:
				return "No internet connection. Running in offline mode."
			case let .httpResponseError(domain):
				return domain
			case .noFactText:
				return "Generated fact doesn't appear to contain text."
			case .factDataError:
				return "Fact data error"
			case .randoFactoDatabaseQuotaExceeded:
				return "Too many favorite fact database requests at once. Try again later."
			case let .userDeletionFailed(reason):
				return "User deletion failed: \(reason)"
			case let .unknown(reason):
				return reason
		}
	}

}
