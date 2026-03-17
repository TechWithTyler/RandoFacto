//
//  UserQueryExtension.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 3/17/26.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import FirebaseFirestore

extension Query {

    // MARK: - Document for User

    // Returns documents for the given user.
    func forUser(_ userEmail: String) -> Query {
        return self.whereField(Firestore.KeyName.user, isEqualTo: userEmail)
    }

}
