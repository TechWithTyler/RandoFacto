//
//  URLRequestExtension.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/24/24.
//  Copyright © 2024 SheftApps. All rights reserved.
//

import Foundation

extension URLRequest {
    
    // HTTP methods for a URL request.
    struct HTTPMethod {
        
        static let get: String = "GET"
        
        static let post: String = "POST"
        
    }
    
    // HTTP header fields for a URL request.
    struct HTTPHeaderField {
        
        static let contentType: String = "Content-Type"
        
        static let accept: String = "Accept"
        
    }
    
}
