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

	let foundTargetWords: Bool

	private enum CodingKeys: String, CodingKey {
		case foundTargetWords = "found-target-words"
	}

}
