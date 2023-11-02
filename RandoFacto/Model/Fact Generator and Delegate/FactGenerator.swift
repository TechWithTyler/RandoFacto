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

	private let factURLString = "https://uselessfacts.jsph.pl/api/v2/facts/random?language=en"

	private let inappropriateWordsCheckerURLString = "https://language-checker.vercel.app/api/check-language"

	// MARK: - Properties - Delegate

	var delegate: FactGeneratorDelegate?

	// MARK: - Initialization

	init(delegate: FactGeneratorDelegate? = nil) {
		self.delegate = delegate
	}

	// MARK: - Fact Generation

	func generateRandomFact() {
		// 1. Create constants.
		guard let url = URL(string: factURLString) else { return }
		let request = URLRequest(url: url)
		let urlSession = URLSession(configuration: .default)
		// 2. Tell the delegate that the fact generator will start generating a random fact.
		delegate?.factGeneratorWillGenerateFact(self)
		// 3. Create the data task with the fact URL.
		let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
			// 4. If an HTTP response other than 200 is returned, log it as an error.
			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
				self.logResponseCodeAsError(response: httpResponse)
				return
			}
			// 5. Log any errors.
			if let error = error {
				self.delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
				return
			}
			// 6. Make sure we can get the fact text. If we can't, an error is logged.
			guard let factText = parseJSON(data: data) else {
				self.logFactDataError()
				return
			}
			// 7. Screen the fact to make sure it doesn't contain inappropriate words. If we get an error or an HTTP response other than 200, log an error. If we get a fact, we know the fact is safe and we can display it. If we get nothing, keep trying to generate a fact until we get a safe one. Once a safe fact is generated, give it to the delegate.
			screenFact(fact: factText) { fact, httpResponse, error in
				if let error = error {
					delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
				} else if let httpResponse = httpResponse {
					logResponseCodeAsError(response: httpResponse)
				} else if let fact = fact {
					if fact.isEmpty {
						logNoTextError()
					} else {
						delegate?.factGeneratorDidGenerateFact(self, fact: fact)
					}
				} else {
					generateRandomFact()
				}
			}
		}
		dataTask.resume()
	}

	func parseJSON(data: Data?) -> String? {
		guard let data = data else {
			return nil
		}
		let decoder = JSONDecoder()
		do {
			let factObject = try decoder.decode(Fact.self, from: data)
			return correctedFactText(factObject.text)
		} catch {
			delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
			return nil
		}
	}

	// MARK: - Fact Text Correction

	func correctedFactText(_ fact: String) -> String {
		let correctedFact = fact.replacingOccurrences(of: "`", with: "'")
		if correctedFact.last == "." || correctedFact.last == "?" || correctedFact.last == "!" || correctedFact.hasSuffix(".\"") {
			return correctedFact
		} else if correctedFact.lowercased().hasPrefix("did you know") && !correctedFact.hasSuffix("?") {
			return correctedFact + "?"
		} else {
			return correctedFact + "."
		}
	}

	// MARK: - Inappropriate Words Checker

	func screenFact(fact: String, completionHandler: @escaping ((String?, HTTPURLResponse?, Error?) -> Void)) {
		guard let url = URL(string: inappropriateWordsCheckerURLString) else {
			completionHandler(nil, nil, nil)
			return }
		let urlSession = URLSession(configuration: .default)
		// Create the URL request
		guard let request = createHTTPRequest(with: url, toScreenFact: fact) else {
			completionHandler(nil, nil, nil)
			return
		}
		delegate?.factGeneratorWillCheckFactForInappropriateWords(self)
		let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
			if let error = error {
				completionHandler(nil, nil, error)
			}
			if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
				completionHandler(nil, httpResponse, nil)
			}
			let factIsInappropriate = self.parseFilterJSON(data: data)
			if !factIsInappropriate {
				completionHandler(fact, nil, nil)
			} else {
				completionHandler(nil, nil, nil)
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
			return factObject.containsInappropriateWords
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

	func logNoTextError() {
		let dataError = NSError(domain: "No fact text", code: 423)
		delegate?.factGeneratorDidFailToGenerateFact(self, error: dataError)
	}

	func logResponseCodeAsError(response: HTTPURLResponse) {
		let responseCode = response.statusCode
		let error = NSError(domain: "\(NetworkError.getErrorDomainForHTTPResponseCode(responseCode)): HTTP Response Status Code \(responseCode)", code: responseCode + 33000)
		delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
	}

}
