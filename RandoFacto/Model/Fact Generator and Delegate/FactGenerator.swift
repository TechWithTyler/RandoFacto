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
		let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
			if let response = response as? HTTPURLResponse {
				self.logResponseCodeAsError(response: response)
				return
			}
			if let error = error {
				self.delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
				return
			}
			guard let factData = self.parseJSON(data: data) else {
				self.logFactDataError(response: response)
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
				return punctuatedFactText(for: text)
			} else {
				return nil
			}
		} catch {
			delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
			return nil
		}
	}

	func punctuatedFactText(for fact: String) -> String {
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
		// Create the URL request
		guard let request = createHTTPRequest(with: url, toScreenFact: fact) else {
			logFactDataError()
			return
		}
		let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
			if let error = error {
				self.delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
				return
			}
			if let response = response as? HTTPURLResponse {
				self.logResponseCodeAsError(response: response)
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

	func createHTTPRequest(with url: URL, toScreenFact fact: String) -> URLRequest? {
		var request = URLRequest(url: url)
		// Your data model that you want to send
		let body = ["content": fact]
		// Convert model to JSON data
		guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
			logFactDataError()
			return nil }
		request.httpMethod = "POST"
		request.httpBody = jsonData
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		return request
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
			delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
			return false
		}
	}

	// MARK: - Error Logging

	func logFactDataError(response: URLResponse? = nil) {
		let dataError = NSError(domain: "Failed to get fact data", code: 523)
		delegate?.factGeneratorDidFailToGenerateFact(self, error: dataError)
	}

	func logDecodeError() {
		let decodeError = NSError(domain: "Failed to decode fact data", code: 135)
		delegate?.factGeneratorDidFailToGenerateFact(self, error: decodeError)
	}

	func logResponseCodeAsError(response: HTTPURLResponse) {
		let responseCode = response.statusCode
		let error = NSError(domain: "\(NetworkError.getErrorDomainForHTTPResponseCode(responseCode)): HTTP Response Status Code \(responseCode)", code: responseCode + 33000)
		delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
	}

}
