//
//  FactData.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//

import Foundation

// MARK: - Decodable Data

struct FactData: Codable {

	let fact: String

}

struct FilteredWordsData: Codable {

	let foundTargetWords: Bool

	private enum CodingKeys: String, CodingKey {
		case foundTargetWords = "found-target-words"
	}

}
