//
//  FactGeneratorErrors.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/15/23.
//

import Foundation

extension FactGenerator {

	enum ErrorDomain: String {

		case failedToGetData = "Failed to get or decode fact data."

		case noText = "No fact text."

	}

	enum ErrorCode: Int {
		
		case failedToGetData = 523

		case noText = 423

	}

}
