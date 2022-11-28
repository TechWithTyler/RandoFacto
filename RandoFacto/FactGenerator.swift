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

	func factGeneratorWillCheckForProfanity(_ generator: FactGenerator)

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
					if let factData = parseJSON(data: data) {
						Task {
							await checkFactForProfanity(fact: factData)
						}
					}
				} else {
					print("Failed to get data")
				}
			}
		}
		delegate?.factGeneratorWillGenerateFact(self)
		task.resume()
	}

	func parseJSON(data: Data) -> String? {
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
		guard let url = URL(string: "\(profanityFilterURLString)\(fact)".replacingOccurrences(of: " ", with: "%20")) else { return }
		let urlSession = URLSession(configuration: .default)
		let task = urlSession.dataTask(with: URLRequest(url: url)) { data, response, error in
			if let error = error {
				delegate?.factGeneratorDidFail(self, error: error)
			} else {
				if let data = data {
					if let cleanFactData = parseProfanityFilterJSON(data: data) {
						delegate?.factGeneratorDidGenerateFact(self, fact: cleanFactData)
					}
				} else {
					print("Failed to get data")
				}
			}
		}
		delegate?.factGeneratorWillCheckForProfanity(self)
		task.resume()
	}

	func parseProfanityFilterJSON(data: Data) -> String? {
		let decoder = JSONDecoder()
		do {
			let filteredFactObject = try decoder.decode(FilteredFactData.self, from: data)
			return filteredFactObject.result
		} catch {
			delegate?.factGeneratorDidFail(self, error: error)
			return nil
		}
	}

}
