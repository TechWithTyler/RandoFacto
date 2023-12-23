//
//  InappropriateWordsCheckerData.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 10/20/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation

// MARK: - Inappropriate Words Checker Data

// Represents whether a fact fed to the inappropriate words checker API contains inappropriate words.
struct InappropriateWordsCheckerData: Codable {

    // Whether a fact contains inappropriate words.
	// This property isn't named the same as it is in the JSON data returned by the inappropriate words checker API, so it's mapped to the correct name using the coding key below.
	let containsInappropriateWords: Bool

    // Use a coding key for any properties with names that differ from those of the data being decoded, or if you want the data being encoded to have different property names from those in your Codable type. For example, if your JSON data has a property named "birth-year" and you want the property name in your Codable type to be birthYear, you can use a coding key.
	private enum CodingKeys: String, CodingKey {
        
        // This maps the InappropriateWordsCheckerData property containsInappropriateWords to the JSON property name "found-target-words".
		case containsInappropriateWords = "found-target-words"
        
	}

}
