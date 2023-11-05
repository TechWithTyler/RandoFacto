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
	
	// The URL of the random facts API.
	private let factURLString = "https://uselessfacts.jsph.pl/api/v2/facts/random?language=en"
	
	// The URL of the inappropriate words checker API.
	private let inappropriateWordsCheckerURLString = "https://language-checker.vercel.app/api/check-language"
	
	// MARK: - Properties - Delegate
	
	var delegate: FactGeneratorDelegate?
	
	// MARK: - Initialization
	
	init(delegate: FactGeneratorDelegate? = nil) {
		self.delegate = delegate
	}
	
	// MARK: - Fact Generation
	
	// This method uses a random facts web API which returns JSON data to generate a random fact.
	func generateRandomFact() {
		// 1. Create constants.
		guard let url = URL(string: factURLString) else { logFactDataError()
			return }
		let request = URLRequest(url: url)
		let urlSession = URLSession(configuration: .default)
		// 2. Tell the delegate that the fact generator will start generating a random fact.
		delegate?.factGeneratorWillGenerateFact(self)
		// 3. Create the data task with the fact URL.
		let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
			// 4. If an HTTP response other than 200 is returned, log it as an error.
			if let httpResponse = response as? HTTPURLResponse, httpResponse.isUnsuccessful {
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
		// 1. If data is nil, log an error.
		guard let data = data else {
			logFactDataError()
			return nil
		}
		// 2. Try to decode the JSON data to create a Fact object, and get the text from it, correcting punctuation as necessary. If decoding fails, log an error.
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
		// Replace incorrect characters and add missing characters to the fact.
		let correctedFact = fact.replacingOccurrences(of: "`", with: "'")
		if correctedFact.hasSuffix(".  ") {
			return "\(correctedFact.dropLast(2))."
		} else if correctedFact.last == "." || correctedFact.last == "?" || correctedFact.last == "!" || correctedFact.hasSuffix(".\"") {
			return correctedFact
		} else if correctedFact.lowercased().hasPrefix("did you know") && !correctedFact.hasSuffix("?") {
			return correctedFact + "?"
		} else {
			return correctedFact + "."
		}
	}
	
	// MARK: - Inappropriate Words Checker
	
	func screenFact(fact: String, completionHandler: @escaping ((String?, HTTPURLResponse?, Error?) -> Void)) {
		// 1. Create constants.
		guard let url = URL(string: inappropriateWordsCheckerURLString) else {
			completionHandler(nil, nil, nil)
			return }
		let urlSession = URLSession(configuration: .default)
		// 2. Create the URL request.
		guard let request = createHTTPRequest(with: url, toScreenFact: fact) else {
			completionHandler(nil, nil, nil)
			return
		}
		// 3. Tell the delegate that the fact is being screened.
		delegate?.factGeneratorWillCheckFactForInappropriateWords(self)
		// 4. Create the data task with the inappropriate words checker URL, handling errors and HTTP responses just as we do in generateRandomFact().
		let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
			if let error = error {
				completionHandler(nil, nil, error)
			}
			if let httpResponse = response as? HTTPURLResponse, httpResponse.isUnsuccessful {
				completionHandler(nil, httpResponse, nil)
			}
			let factIsInappropriate = parseFilterJSON(data: data)
			if !factIsInappropriate {
				completionHandler(fact, nil, nil)
			} else {
				completionHandler(nil, nil, nil)
			}
		}
		dataTask.resume()
	}
	
	func createHTTPRequest(with url: URL, toScreenFact fact: String) -> URLRequest? {
		// Create the URL request.
		var request = URLRequest(url: url)
		// 2. Specify the data model that you want to send.
		let body = ["content": fact]
		// 3. Try to convert model to JSON data. If conversion fails, log an error.
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: body)
			request.httpMethod = "POST"
			request.httpBody = jsonData
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			return request
		} catch {
			delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
			return nil
		}
	}
	
	func parseFilterJSON(data: Data?) -> Bool {
		// 1. If data is nil, be on the safe side and treat the fact as inappropriate.
		guard let data = data else {
			return true
		}
		// 2. Try to decode the JSON data to create an InappropriateWordsCheckerData object, and get whether the fact is inappropriate from it, returning the fact if it's appropriate. If decoding fails, log an error.
		let decoder = JSONDecoder()
		do {
			let factObject = try decoder.decode(InappropriateWordsCheckerData.self, from: data)
			return factObject.containsInappropriateWords
		} catch {
			delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
			return true
		}
	}
	
	// MARK: - Custom Error Logging
	
	// These methods log any errors not handled by catch blocks or completion handlers.
	
	func logFactDataError(response: URLResponse? = nil) {
		let dataError = NSError(domain: "Failed to get fact data", code: 523)
		delegate?.factGeneratorDidFailToGenerateFact(self, error: dataError)
	}
	
	func logNoTextError() {
		let dataError = NSError(domain: "No fact text", code: 423)
		delegate?.factGeneratorDidFailToGenerateFact(self, error: dataError)
	}
	
	// MARK: - Unsuccessful HTTP Response Code As Error
	
	// This method creates an error from the given HTTP response's code and logs it.
	func logResponseCodeAsError(response: HTTPURLResponse) {
		let responseMessage = response.errorDomainForResponseCode
		let responseCode = response.statusCode
		let error = NSError(domain: "\(responseMessage): HTTP Response Status Code \(responseCode)", code: responseCode + 33000)
		delegate?.factGeneratorDidFailToGenerateFact(self, error: error)
	}
	
}
