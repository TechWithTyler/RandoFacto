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

protocol FactGeneratorDelegate {

	func factGeneratorWillGenerateFact(_ generator: FactGenerator)

	func factGeneratorDidGenerateFact(_ generator: FactGenerator, fact: String)

	func factGeneratorDidFail(_ generator: FactGenerator, error: Error)

}

struct FactGenerator {

	var delegate: FactGeneratorDelegate?

	private let urlString = "https://uselessfacts.jsph.pl/random.json?language=en"

	func generateRandomFact() {
		guard let url = URL(string: urlString) else { return }
		let urlSession = URLSession(configuration: .default)
		let task = urlSession.dataTask(with: URLRequest(url: url)) { data, response, error in
			if let error = error {
				delegate?.factGeneratorDidFail(self, error: error)
			} else {
				if let data = data {
					if let factData = parseJSON(data: data) {
						delegate?.factGeneratorDidGenerateFact(self, fact: factData)
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

}
