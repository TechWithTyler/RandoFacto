//
//  FavoriteFact.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/13/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation
import FirebaseFirestoreSwift

// MARK: - Favorite Fact Data

// We need to represent favorite facts as a separate object from facts returned by the fact generator API, because having more properties than needed will result in the object not decoding properly.
struct FavoriteFact: Codable, Equatable {

	@DocumentID var id: String?

	var text: String

	var user: String

	static func ==(lFact: FavoriteFact, rFact: FavoriteFact) -> Bool {
		return lFact.text == rFact.text
	}

}
