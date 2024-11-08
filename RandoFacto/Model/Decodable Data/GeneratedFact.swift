//
//  GeneratedFact.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation

// MARK: - Generated Fact Data

// Represents the JSON data returned by the random facts API.
// Codable is a type alias for Encodable and Decodable.
struct GeneratedFact: Codable {

    // Properties of Codable objects must be Codable themselves. Standard Swift data types, such as String, Int, and Bool, are Codable.
    // When decoding data, your Codable type must not have any more properties than what the encoded data has. For example, if you're decoding JSON data that has name and age properties, the Codable type can't also have a birthYear property or else it can't decode properly. Your Codable type can, however, have fewer properties than the encoded data. In the case of GeneratedFact, it contains fewer properties than the original encoded JSON data. because that's the only property this app is using of the properties defined in the JSON data.
	// This property is named exactly as it is in the JSON data returned by the random facts API.
	let text: String

}
