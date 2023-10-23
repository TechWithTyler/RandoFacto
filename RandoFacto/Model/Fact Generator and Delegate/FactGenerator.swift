//
//  FactGenerator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import Foundation

struct FactGenerator {

	// MARK: - Properties - URLs

	private let factURLString = "https://api.api-ninjas.com/v1/facts?limit=1"

	private let inappropriateWordsCheckerURLString = "https://language-checker.vercel.app/api/check-language"

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
			guard let factData = self.parseJSON(data: data) else {
				self.logFactDataError()
				return
			}
			delegate?.factGeneratorWillCheckFactForInappropriateWords(self)
			checkFactForInappropriateWords(fact: factData)
		}
		dataTask.resume()
	}

	func parseJSON(data: Data?) -> String? {
		guard let data = data else {
			return nil
		}
		let decoder = JSONDecoder()
		do {
			if let factObject = try decoder.decode([FactData].self, from: data).first {
				let text = factObject.fact
				return formattedFactText(for: text)
			} else {
				return nil
			}
		} catch {
			delegate?.factGeneratorDidFail(self, error: error)
			return nil
		}
	}

	func formattedFactText(for fact: String) -> String {
		if fact.last == "." || fact.last == "?" || fact.last == "!" || fact.hasSuffix(".\"") {
			return fact
		} else if fact.lowercased().hasPrefix("did you know") {
			return fact + "?"
		} else {
			return fact + "."
		}
	}

	// MARK: - Inappropriate Words Checker

	func checkFactForInappropriateWords(fact: String) {
		guard let url = URL(string: inappropriateWordsCheckerURLString) else { return }
		let urlSession = URLSession(configuration: .default)
		// Your data model that you want to send
		let body = ["content": fact]
		// Convert model to JSON data
		guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { 
			logFactDataError()
			return }
		// Create the URL request
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = jsonData
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		let dataTask = urlSession.dataTask(with: request) { [self] data, _, error in
			if let error = error {
				self.delegate?.factGeneratorDidFail(self, error: error)
				return
			}
			let factIsInappropriate = self.parseFilterJSON(data: data)
			if !factIsInappropriate {
				delegate?.factGeneratorDidGenerateFact(self, fact: fact)
			} else {
				generateRandomFact()
			}
		}
		dataTask.resume()
	}

	func parseFilterJSON(data: Data?) -> Bool {
		guard let data = data else {
			return false
		}
		let decoder = JSONDecoder()
		do {
			let factObject = try decoder.decode(InappropriateWordsCheckerData.self, from: data)
			return factObject.foundTargetWords
		} catch {
			delegate?.factGeneratorDidFail(self, error: error)
			return false
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
