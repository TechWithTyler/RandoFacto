//
//  Fact.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

// MARK: - Fact Data

struct Fact: Codable {

	// This property is named exactly as it is in the JSON data returned by the random facts API.
	let text: String

}
