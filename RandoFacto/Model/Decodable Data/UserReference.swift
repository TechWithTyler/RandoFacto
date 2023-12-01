//
//  UserReference.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/13/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation
import Firebase

// MARK: - Registered User Reference Data

// Represents a registered user.
extension User {

	struct Reference: Codable {

        // The email of the user.
		let email: String

	}

}
