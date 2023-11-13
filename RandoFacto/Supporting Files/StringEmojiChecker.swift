//
//  StringEmojiChecker.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/10/23.
//

import Foundation

extension String {
	var containsEmoji: Bool {
		for scalar in unicodeScalars {
			if scalar.properties.isEmoji {
				return true
			}
		}
		return false
	}
}
