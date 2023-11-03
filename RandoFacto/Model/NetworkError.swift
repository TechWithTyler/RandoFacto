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

	// Unknown error, with the given reason.
	case unknown(reason: String)

	// MARK: - Error Case Definitions - Fact Generation

	// No internet connection.
	case noInternet

	// Bad HTTP response, with the given error domain.
	case badHTTPResponse(domain: String)

	// Generated fact doesn't contain text.
	case noFactText

	// Fact generation/screening error.
	case factDataError

	// MARK: - Error Case Definitions - RandoFacto Database

	// Too many RandoFacto database requests (e.g. repeatedly favoriting and unfavoriting the same fact).
	case randoFactoDatabaseQuotaExceeded

	// Account deletion failed, with the given reason.
	case userDeletionFailed(reason: String)

	// MARK: - HTTP Response Status Code To Error Domain String

	// This method returns the given HTTP response code's corresponding message.
	static func getErrorDomainForHTTPResponseCode(_ code: Int) -> String {
		switch code {
			case 400: return "Bad Request"
			case 401: return "Unauthorized"
			case 403: return "Forbidden (maybe access to this service isn't allowed from your current network)"
			case 404: return "Not Found (maybe service temporarily down)"
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
		return chooseErrorDescriptionToLog()
	}

	// This method chooses the error's description based on the error.
	func chooseErrorDescriptionToLog() -> String? {
		switch self {
			case .noInternet:
				return "No internet connection. Running in offline mode."
			case let .badHTTPResponse(domain):
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
