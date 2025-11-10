//
//  UserDeletionStage.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/10/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

// MARK: - Imports

import Foundation
import FirebaseAuth

extension User {

	// The current stage of a user's account deletion.
	enum AccountDeletionStage : String {

        // MARK: - User Deletion Stages

        // The account's favorite facts and user reference are being deleted.
		case data
		
        // The account itself is being deleted.
		case account

	}

}
