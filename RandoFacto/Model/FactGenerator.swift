//
//  FactGenerator.swift
//  RandoFacto
//
//  Created by TechWithTyler on 11/21/22.
//

import Foundation

// MARK: - Fact Generator Delegate

protocol FactGeneratorDelegate {

	func factGeneratorWillGenerateFact(_ generator: FactGenerator)

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String)

	func factGeneratorDidFail(_ generator: FactGenerator, error: Error)

}

struct FactGenerator {

	// MARK: - Properties - URLs

	private let factURLString = "https://api.api-ninjas.com/v1/facts?limit=1"

	// MARK: - Properties - Delegate

	var delegate: FactGeneratorDelegate?

	// MARK: - Initialization

	init(delegate: FactGeneratorDelegate? = nil) {
		self.delegate = delegate
	}

	// MARK: - Fact Generation

	func generateRandomFact() {
		guard let url = URL(string: factURLString) else { return }
		var request = URLRequest(url: url)
		let urlSession = URLSession(configuration: .default)
		request.setValue(factGeneratorApiKey, forHTTPHeaderField: "X-Api-Key")
		delegate?.factGeneratorWillGenerateFact(self)
		let dataTask = urlSession.dataTask(with: request) { [self] data, _, error in
			if let error = error {
				self.delegate?.factGeneratorDidFail(self, error: error)
				return
			}
			guard let data = data, let factData = self.parseJSON(data: data) else {
				self.logFactDataError()
				return
			}
			delegate?.factGeneratorDidGenerateFact(self, fact: factData)
		}
		dataTask.resume()
	}

	func parseJSON(data: Data) -> String? {
		let decoder = JSONDecoder()
		do {
			if let factObject = try decoder.decode([FactData].self, from: data).first {
				return factObject.fact + "."
			} else {
				logDecodeError()
				return nil
			}
		} catch {
			delegate?.factGeneratorDidFail(self, error: error)
			return nil
		}
	}

	// MARK: - Error Logging

	func logFactDataError() {
		let dataError = NSError(domain: "Failed to get fact data", code: 523)
		delegate?.factGeneratorDidFail(self, error: dataError)
	}

	func logDecodeError() {
		let decodeError = NSError(domain: "Failed to decode fact data", code: 135)
		delegate?.factGeneratorDidFail(self, error: decodeError)
	}

}
