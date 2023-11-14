//
//  UserDeletionStage.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/10/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation
import Firebase

extension User {

	// The current stage of a user's account deletion.
	enum AccountDeletionStage : String {

		case data
		
		case account

	}

}
