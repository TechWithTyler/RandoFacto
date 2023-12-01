//
//  HTTPResponseExtension.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/3/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation

extension HTTPURLResponse {

	// MARK: - Unsuccessful Response Check

	// Whether the HTTP response indicates a failure (the code is not in the 2xx range).
	var isUnsuccessful: Bool {
        let range = 200...299
        return !range.contains(statusCode)
	}

	// MARK: - HTTP Response Status Code To Error Domain String

	// Returns the given HTTP response code's corresponding message.
	var errorDomainForResponseCode: String {
		switch statusCode {
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

	// MARK: - Unsuccessful HTTP Response Code As Error

	// This method creates an error from the given HTTP response's code and logs it.
	func logAsError(completionHandler: ((Error) -> Void)) {
		let responseMessage = errorDomainForResponseCode
		let responseCode = statusCode
        let errorDomain = "\(responseMessage): HTTP Response Status Code \(responseCode)"
        let errorCode = responseCode + 33000 // e.g. 33404 (FD404)
		let error = NSError(domain: errorDomain, code: errorCode)
		completionHandler(error)
	}

}
