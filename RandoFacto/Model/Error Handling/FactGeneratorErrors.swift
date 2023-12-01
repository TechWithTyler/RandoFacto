//
//  FactGeneratorErrors.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/15/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
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

	}
    
    // MARK: - Fact Generator Custom Error Logging

    // These methods log any errors not handled by catch blocks or completion handlers.

    func logFactDataError(completionHandler: ((Error) -> Void)) {
        let dataError = NSError(domain: ErrorDomain.failedToGetData.rawValue, code: ErrorCode.failedToGetData.rawValue)
        completionHandler(dataError)
    }

    func logNoTextError(completionHandler: ((Error) -> Void)) {
        let dataError = NSError(domain: ErrorDomain.noText.rawValue, code: ErrorCode.noText.rawValue)
        completionHandler(dataError)
    }

}
