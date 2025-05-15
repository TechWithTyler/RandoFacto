//
//  URLRequestExtension.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/24/24.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import Foundation

extension URLRequest {
    
    // HTTP methods for a URL request.
    struct HTTPMethod {

        // The GET HTTP method.
        static let get: String = "GET"

        // The POST HTTP method.
        static let post: String = "POST"
        
    }
    
    // HTTP header fields for a URL request.
    struct HTTPHeaderField {

        // The Content-Type HTTP header field.
        static let contentType: String = "Content-Type"

        // The Accept HTTP header field.
        static let accept: String = "Accept"
        
    }
    
}
