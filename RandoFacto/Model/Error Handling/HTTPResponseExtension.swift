//
//  HTTPResponseExtension.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/3/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import Foundation

extension HTTPURLResponse {

	// MARK: - Unsuccessful Response Check

	// Whether the HTTP response indicates a failure (the code is not in the 2xx range).
	var isUnsuccessful: Bool {
        let range = 200...299
        let unsuccessful = !range.contains(statusCode)
        return unsuccessful
	}

	// MARK: - HTTP Response Status Code To Error Domain String

	// Returns the given HTTP response code's corresponding message.
	var errorDomainForResponseCode: String {
        switch statusCode {
            // Known status codes
			case 400: return "Bad Request"
			case 401: return "Unauthorized"
			case 403: return "Forbidden (Maybe Access To This Service Isn't Allowed From Your Current Network)"
			case 404: return "Not Found (Maybe Service Temporarily Down)"
			case 408: return "Request Timeout (Maybe Bad Internet Connection)"
			case 500: return "Internal Server Error"
			case 502: return "Bad Gateway"
			case 503: return "Service Unavailable"
			case 504: return "Gateway Timeout"
			case 505: return "HTTP Version Not Supported"
            // Unknown status code
			default: return "Unknown Response"
		}
	}

	// MARK: - Unsuccessful HTTP Response Code As Error

	// This method creates an error from the given HTTP response's code and logs it.
	func logAsError() -> Error {
        // 1. Get the error domain and response code.
		let responseMessage = errorDomainForResponseCode
		let responseCode = statusCode
        // 2. Use the error domain and response code to create a new error domain including the code.
        let errorDomain = "\(responseMessage): HTTP Response Status Code \(responseCode)"
        // 3. Add 33000 to the response code.
        let errorCode = responseCode + 33000 // e.g. 33404 (FD404)
        // 4. Create and return the error.
		let error = NSError(domain: errorDomain, code: errorCode)
		return error
	}

}
