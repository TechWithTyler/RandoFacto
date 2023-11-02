//
//  FactData.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

// MARK: - Fact Data

struct FactData: Codable {

	let id: String

	let text: String

	let source: String

	let sourceURL: String

	let language: String

	let permalink: String

	enum CodingKeys: String, CodingKey {
		case id
		case text
		case source
		case sourceURL = "source_url"
		case language
		case permalink
	}
}
