//
//  StringEmojiChecker.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/10/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation

extension String {

	var containsEmoji: Bool {
		for scalar in unicodeScalars {
			// Check if the scalar is an emoji and not a numeric character
			if scalar.properties.isEmoji && scalar.properties.isEmojiPresentation {
				return true
			}
		}
		return false
	}

}
