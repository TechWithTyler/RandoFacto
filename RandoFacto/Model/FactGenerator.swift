//
//  FactGenerator.swift
//  RandoFacto
//
//  Created by TechWithTyler on 11/21/22.
//

import Foundation

// MARK: - Decodable Data

struct FactData: Decodable {

	let fact: String

}

//struct FilteredFactData: Decodable {
//
//	let result: String
//
//}

// MARK: - Fact Generator Delegate

protocol FactGeneratorDelegate {

	func factGeneratorWillGenerateFact(_ generator: FactGenerator)

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String)

	func factGeneratorDidFail(_ generator: FactGenerator, error: Error)

}

struct FactGenerator {

	// MARK: - Properties - URLs

	private let factURLString = "https://api.api-ninjas.com/v1/facts?limit=1"

	private var profanityFilterURLString = "https://www.purgomalum.com/service/json?text="

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
		request.setValue(factGeneratorApiKey, forHTTPHeaderField: "X-Api-Key")
		let urlSession = URLSession(configuration: .default)
		delegate?.factGeneratorWillGenerateFact(self)
		urlSession.dataTask(with: request) { [self] data, response, error in
			if let error = error {
				self.delegate?.factGeneratorDidFail(self, error: error)
				return
			}
			guard let data = data else {
				self.logFactDataError()
				return
			}
				guard let factData = self.parseJSON(data: data) else {
					self.logFactDataError()
					return
				}
			delegate?.factGeneratorDidGenerateFact(self, fact: factData)
		}.resume()
	}

	func parseJSON(data: Data) -> String? {
		let decoder = JSONDecoder()
		do {
			if let factObject = try decoder.decode([FactData].self, from: data).first {
				return factObject.fact + "."
			} else {
				delegate?.factGeneratorDidFail(self, error: NSError(domain: "Failed to decode fact data", code: 135))
				return nil
			}
		} catch {
			delegate?.factGeneratorDidFail(self, error: error)
			return nil
		}
	}

	// MARK: - Profanity Check
//
//	func checkFactForProfanity(fact: String) {
//		let urlString = "\(profanityFilterURLString)\(fact)"
//		guard let url = URL(string: urlString) else {
//			print("Trying again…")
//				generateRandomFact()
//			return
//		}
//		let urlSession = URLSession(configuration: .default)
//		let task = urlSession.dataTask(with: URLRequest(url: url)) { data, response, error in
//			if let error = error {
//				delegate?.factGeneratorDidFail(self, error: error)
//			} else {
//				if let data = data {
//						if let cleanFactData = parseProfanityFilterJSON(data: data) {
//							print("Profanity URL: \(url.absoluteString)")
//							let containsProfanity = cleanFactData.contains("*")
//							if containsProfanity || cleanFactData.isEmpty {
//								print("Trying again…")
//								generateRandomFact()
//							} else {
//								delegate?.factGeneratorDidGenerateFact(self, fact: cleanFactData.replacingOccurrences(of: "`", with: "'"))
//							}
//						} else {
//							logFilteredFactDataError()
//						}
//				} else {
//					logFilteredFactDataError()
//				}
//			}
//		}
//		task.resume()
//	}
//
//	func parseProfanityFilterJSON(data: Data) -> String? {
//		let decoder = JSONDecoder()
//		do {
//			let filteredFactObject = try decoder.decode(FilteredFactData.self, from: data)
//			return filteredFactObject.result
//		} catch {
//			delegate?.factGeneratorDidFail(self, error: error)
//			return nil
//		}
//	}

	// MARK: - Error Logging

	func logFactDataError() {
		let dataError = NSError(domain: "Failed to get fact data", code: 523)
		delegate?.factGeneratorDidFail(self, error: dataError)
	}

	func logFilteredFactDataError() {
		let dataError = NSError(domain: "Failed to get filtered fact data", code: 524)
		delegate?.factGeneratorDidFail(self, error: dataError)
	}

}
