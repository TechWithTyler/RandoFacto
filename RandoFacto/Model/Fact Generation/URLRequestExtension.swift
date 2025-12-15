//
//  URLRequestExtension.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/24/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import Foundation

extension URLRequest {

    // MARK: - HTTP Methods

    // HTTP methods for a URL request.
    struct HTTPMethod {

        // The GET HTTP method, used to get data from an HTTP request.
        static let get: String = "GET"

        // The POST HTTP method, used to send data via an HTTP request.
        static let post: String = "POST"

    }

    // MARK: - HTTP Header Fields

    // HTTP header fields for a URL request.
    struct HTTPHeaderField {

        // The Content-Type HTTP header field.
        static let contentType: String = "Content-Type"

        // The Accept HTTP header field.
        static let accept: String = "Accept"
        
    }
    
}
