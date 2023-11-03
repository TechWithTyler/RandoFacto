//
//  InappropriateWordsCheckerData.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 10/20/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

// MARK: - Inappropriate Words Checker Data

struct InappropriateWordsCheckerData: Codable {

	// This property isn't named the same as it is in the JSON data returned by the inappropriate words checker API, so it's mapped to the correct name using the coding key below.
	let containsInappropriateWords: Bool

	// Use CodingKeys to point a custom property name to the correct property name in the JSON data.
	private enum CodingKeys: String, CodingKey {
		case containsInappropriateWords = "found-target-words"
	}

}
