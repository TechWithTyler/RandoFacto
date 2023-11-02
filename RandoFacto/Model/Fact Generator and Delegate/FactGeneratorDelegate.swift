//
//  FactGeneratorDelegate.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

// MARK: - Fact Generator Delegate

protocol FactGeneratorDelegate {

	func factGeneratorWillGenerateFact(_ generator: FactGenerator)

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String, source: String, sourceURL: String)

	func factGeneratorWillCheckFactForInappropriateWords(_ generator: FactGenerator)

	func factGeneratorDidFailToGenerateFact(_ generator: FactGenerator, error: Error)

}
