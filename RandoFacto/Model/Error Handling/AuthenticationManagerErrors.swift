//
//  AuthenticationManagerErrors.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/24/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import Foundation

extension AuthenticationManager {
    
    // MARK: - Authentication Manager Error Domains
    
    enum ErrorDomain: String {
        
        case userAccountNotFound = "User account not found."
        
        case userReferenceNotFound = "User reference not found."
        
    }
    
    // MARK: - Authentication Manager Error Codes
    
    enum ErrorCode: Int {
        
        case userAccountNotFound = 545
        
        case userReferenceNotFound = 143
        
    }
    
}
