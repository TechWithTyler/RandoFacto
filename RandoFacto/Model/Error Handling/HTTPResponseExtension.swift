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

	// Whether the HTTP response indicates a failure (the code isn't in the 2xx range).
	var isUnsuccessful: Bool {
        let successStatusCodeRange = 200...299
        let unsuccessful = !successStatusCodeRange.contains(statusCode)
        return unsuccessful
	}

	// MARK: - HTTP Response Status Code To Error Domain String

	// Returns the given HTTP response code's corresponding message.
    var errorDomainForResponseCode: String {

        switch statusCode {

            // Known HTTP status codes

            // 400 Bad Request
            // The server couldn't understand or process the request because something about the request was invalid or malformed.
            case 400: return "Bad Request"

            // 401 Unauthorized
            // The request requires authentication, or the supplied authentication credentials are missing or invalid.
            case 401: return "Unauthorized"

            // 403 Forbidden
            // The server understood the request but refuses to fulfill it, or the client doesn't have permission to access the requested resource. For example, a school's Wi-Fi network might restrict access due to potentially inappropriate content.
            case 403: return "Forbidden"

            // 404 Not Found
            // The requested resource could not be found on the server.
            case 404: return "Not Found"

            // 408 Request Timeout:
            // The server didn't receive a complete request from the client within the amount of time it was prepared to wait.
            case 408: return "Request Timeout"

            // 500 Internal Server Error
            // The server encountered an unexpected condition that prevented it from fulfilling the request. In RandoFacto's case, the fact server is maintained by a 3rd-party developer, Joseph Paul, so issues that arise with it are outside of our control.
            case 500: return "Internal Server Error (Maybe Service Temporarily Down)"

            // 502 Bad Gateway
            // A server acting as a gateway or proxy received an invalid response from an upstream server.
            case 502: return "Bad Gateway"

            // 503 Service Unavailable
            // The server is currently unable to handle the request, usually because it's overloaded or temporarily undergoing maintenance.
            case 503: return "Service Unavailable"

            // 504 Gateway Timeout
            // A server acting as a gateway or proxy didn't receive a timely response from an upstream server.
            case 504: return "Gateway Timeout"

            // 505 HTTP Version Not Supported
            // The server doesn't support the HTTP version used in the request.
            case 505: return "HTTP Version Not Supported"

            // Unknown status code
            // The server returned an HTTP status code that isn't explicitly handled above.
            default: return "Unknown Response"
        }
    }

	// MARK: - Unsuccessful HTTP Response Code As Error

	// Returns an error from the given HTTP response's code, or nil if it indicates a success (response code in the 2xx range).
    var error: Error? {
        // 1. Get the error domain and response code.
        guard isUnsuccessful else { return nil }
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
