//
//  FactGeneratorErrors.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/15/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

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
            return 33000...33999
        }

	}
    
    // MARK: - Fact Generator Custom Error Logging

    // These methods log any errors not handled by catch blocks or completion handlers.

    func logFactDataError() -> Error {
        let dataError = factDataError
        return dataError
    }

    func logNoTextError() -> Error {
        let dataError = NSError(domain: ErrorDomain.noText.rawValue, code: ErrorCode.noText.rawValue)
        return dataError
    }

}
