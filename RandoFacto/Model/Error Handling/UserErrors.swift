//
//  UserErrors.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/24/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import FirebaseAuth

extension User {

    // User-related errors.
    struct Errors {

        // The error thrown when a user is logged out due to failed signup/login.
        static let authenticationActionFailed = NSError(domain: "Authentication action failed.", code: 585)

        // The error thrown when a user account can't be found.
        static let accountNotFound = NSError(domain: "User account not found.", code: 545)

        // The error thrown when a user's reference can't be found.
        static let referenceNotFound = NSError(domain: "User reference not found.", code: 143)

    }

}
