//
//  FirestoreNames.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/19/24.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import Firebase

extension Firestore {
    
    // RandoFacto Firestore collection names
    struct CollectionName {
        
        // The name of the collection containing registered users in the Firestore database.
        static let users = "users"
        
        // The name of the collection containing favorite facts in the Firestore database.
        static let favoriteFacts = "favoriteFacts"
        
    }
    
    // RandoFacto Firestore key names
    struct KeyName {
        
        // The key name of a fact's text in the Firestore database.
        static let factText = "text"
        
        // The key name of a fact's associated user email.
        static let user = "user"
        
        // The key name of a registered user's email.
        static let email = "email"
        
    }
   
}

