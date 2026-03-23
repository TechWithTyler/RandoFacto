//
//  FactGeneratorErrors.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/15/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import Foundation

extension FactGenerator {
    
    // MARK: - Fact Generator Error Domains

	enum ErrorDomain: String {

		case failedToGetData = "Failed to get or decode fact data."

		case noText = "No fact text."

	}
    
    // MARK: - Fact Generator Error Codes

	enum ErrorCode: Int {
		
		case failedToGetData = 523

		case noText = 423

        static var factDataHTTPResponseCodeRange: ClosedRange<Int> {
            // FD (33) + HTTP status code
            return 33000...33999
        }

	}

}
