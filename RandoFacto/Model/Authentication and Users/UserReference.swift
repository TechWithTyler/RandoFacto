//
//  UserReference.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/13/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import Foundation
import FirebaseAuth

// MARK: - Registered User Reference Data

extension User {

    // Represents a registered user.
	struct Reference: Codable {

        // The email of the user.
		let email: String

	}

}
