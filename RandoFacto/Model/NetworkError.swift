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

	case httpResponseError(domain: String)

	case noText

	case dataError

	case quotaExceeded

	case userDeletionFailed(reason: String)

	// MARK: - HTTP Response Status Code To Error Domain String

	static func getDomainForResponseCode(_ code: Int) -> String {
		switch code {
			case 400: return "Bad Request"
			case 401: return "Unauthorized"
			case 403: return "Forbidden"
			case 404: return "Not Found"
			case 408: return "Request Timeout"
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
			case .noText:
				return "Generated fact doesn't appear to contain text."
			case .dataError:
				return "Fact data error"
			case .quotaExceeded:
				return "Too many favorite fact database requests at once. Try again later."
			case let .userDeletionFailed(reason):
				return "User deletion failed: \(reason)"
			case let .unknown(reason):
				return reason
		}
	}

}
