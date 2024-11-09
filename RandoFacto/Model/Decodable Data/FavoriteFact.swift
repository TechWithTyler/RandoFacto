//
//  FavoriteFact.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/13/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation
import FirebaseFirestore

// MARK: - Favorite Fact Data

// We need to represent favorite facts as a separate object from facts returned by the fact generator API, because having more properties than the JSON data has will result in the object not decoding properly.
struct FavoriteFact: Codable, Equatable {

    // The ID which identifies this favorite fact. The @DocumentID property wrapper is provided by Firebase.
	@DocumentID var id: String?

    // The fact text.
	var text: String

    // The user associated with the favorite fact.
	var user: String

    // Checks whether 2 favorite facts are equal by checking their text.
	static func ==(lFact: FavoriteFact, rFact: FavoriteFact) -> Bool {
		return lFact.text == rFact.text
	}

}
