//
//  FirestoreNames.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/19/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import FirebaseFirestore

extension Firestore {
    
    // MARK - RandoFacto Firestore Collection Names

    struct CollectionName {
        
        // The name of the collection containing registered users in the Firestore database.
        static let users = "users"
        
        // The name of the collection containing favorite facts in the Firestore database.
        static let favoriteFacts = "favoriteFacts"
        
    }
    
    // MARK: - RandoFacto Firestore Key Names
    
    struct KeyName {
        
        // The key name of a fact's text in the Firestore database.
        static let factText = "text"
        
        // The key name of a fact's associated user email.
        static let user = "user"
        
        // The key name of a registered user's email.
        static let email = "email"
        
    }
   
}

