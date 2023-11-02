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

	let containsInappropriateWords: Bool

	// Use CodingKeys to point a custom property name to the correct property name in the JSON data.
	private enum CodingKeys: String, CodingKey {
		case containsInappropriateWords = "found-target-words"
	}

}
