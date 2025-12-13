//
//  FavoriteFactsDatabaseErrors.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/24/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import Foundation

extension FavoriteFactsDatabase {
    
    // MARK: - Favorite Facts Database Error Domains
    
    enum ErrorDomain: String {
        
        case favoriteFactReferenceNotFound = "Favorite fact reference not found."

    }
    
    // MARK: - Favorite Facts Database Error Codes
    
    enum ErrorCode: Int {
        
        case favoriteFactReferenceNotFound = 144

    }
    
}
