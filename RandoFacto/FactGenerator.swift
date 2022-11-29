//
//  FactGenerator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//

import Foundation

struct FactData: Decodable {

	let text: String

}

struct FilteredFactData: Decodable {

	let result: String

}

protocol FactGeneratorDelegate {

	func factGeneratorWillGenerateFact(_ generator: FactGenerator)

	func factGeneratorWillRetry(_ generator: FactGenerator)

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String)

	func factGeneratorDidFail(_ generator: FactGenerator, error: Error)

}

struct FactGenerator {

	var delegate: FactGeneratorDelegate?

	private let factURLString = "https://uselessfacts.jsph.pl/random.json?language=en"

	private var profanityFilterURLString = "https://www.purgomalum.com/service/json?text="

	init(delegate: FactGeneratorDelegate?) {
		self.delegate = delegate
	}

	func generateRandomFact() async {
		guard let url = URL(string: factURLString) else { return }
		let urlSession = URLSession(configuration: .default)
		let task = urlSession.dataTask(with: URLRequest(url: url)) { data, response, error in
			if let error = error {
				delegate?.factGeneratorDidFail(self, error: error)
			} else {
				if let data = data {
					Task {
						if let factData = await parseJSON(data: data) {
								await checkFactForProfanity(fact: factData)
						} else {
							logFactDataError()
						}
					}
				} else {
					logFactDataError()
				}
			}
		}
		delegate?.factGeneratorWillGenerateFact(self)
		task.resume()
	}

	func parseJSON(data: Data) async -> String? {
		let decoder = JSONDecoder()
		do {
			let factObject = try decoder.decode(FactData.self, from: data)
			return factObject.text
		} catch {
			delegate?.factGeneratorDidFail(self, error: error)
			return nil
		}
	}

	func checkFactForProfanity(fact: String) async {
		let urlString = "\(profanityFilterURLString)\(fact)"
		guard let url = URL(string: urlString.replacingOccurrences(of: " ", with: "%20").replacingOccurrences(of: "\n", with: "%0A")) else {
			Task {
				await generateRandomFact()
				delegate?.factGeneratorWillRetry(self)
			}
			return
		}
		let urlSession = URLSession(configuration: .default)
		let task = urlSession.dataTask(with: URLRequest(url: url)) { data, response, error in
			if let error = error {
				delegate?.factGeneratorDidFail(self, error: error)
			} else {
				if let data = data {
					Task {
						if let cleanFactData = await parseProfanityFilterJSON(data: data) {
							let containsProfanity = cleanFactData.contains("*")
							if containsProfanity || cleanFactData.isEmpty {
								await generateRandomFact()
							} else {
								delegate?.factGeneratorDidGenerateFact(self, fact: cleanFactData)
							}
						} else {
							logFilteredFactDataError()
						}
					}
				} else {
					logFilteredFactDataError()
				}
			}
		}
		task.resume()
	}

	func parseProfanityFilterJSON(data: Data) async -> String? {
		let decoder = JSONDecoder()
		do {
			let filteredFactObject = try decoder.decode(FilteredFactData.self, from: data)
			return filteredFactObject.result
		} catch {
			delegate?.factGeneratorDidFail(self, error: error)
			return nil
		}
	}

	func logFactDataError() {
		let dataError = NSError(domain: "Failed to get fact data", code: 523)
		delegate?.factGeneratorDidFail(self, error: dataError)
	}

	func logFilteredFactDataError() {
		let dataError = NSError(domain: "Failed to get filtered fact data", code: 524)
		delegate?.factGeneratorDidFail(self, error: dataError)
	}

}
