//
//  FactGenerator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation

struct FactGenerator {
    
    // MARK: - Properties - Content Type
    
    let jsonContentType = "application/json"
    
    // MARK: - Properties - URLs
    
    // The URL of the random facts API.
    private var factURLString: String {
        // 1. The scheme specifies the protocol used to access the resource. In this case, it's "https" (Hypertext Transfer Protocol Secure). This indicates that the data transferred between the app and the server is encrypted for security.
        let scheme = "https"
        // 2. The domain or host is the main part of the URL that identifies the server where the resource is located. In this case, the domain is "uselessfacts.jsph.pl", created by Joeseph Paul, which is what jsph.pl stands for (usually "pl" means a website in Poland).
        let subdomain = "uselessfacts"
        let domain = "jsph.pl"
        // 3. The path indicates the specific resource or location on the server that the client is requesting. In this URL, the path is "/api/vX/facts/random", where X represents the API version.
        let apiVersion = 2
        let randomFactPath = "api/v\(apiVersion)/facts/random"
        // 4. Query parameters are additional information provided in the URL to modify the request. They follow a question mark (?) and are separated by ampersands (&). In this URL, there is one query parameter, "language=en", indicating that the client is requesting a fact in English.
        let lowercaseLanguageCode = "en"
        let languageQueryParameter = "language=\(lowercaseLanguageCode)"
        // 5. Put the components together to create the full URL string to return.
        let urlString = "\(scheme)://\(subdomain).\(domain)/\(randomFactPath)?\(languageQueryParameter)"
        return urlString
    }

    
    // The URL of the inappropriate words checker API.
    private let inappropriateWordsCheckerURLString: String = "https://language-checker.vercel.app/api/check-language"
    
    // MARK: - Fact Generation
    
    // This method uses a random facts web API which returns JSON data to generate a random fact.
    func generateRandomFact(didBeginHandler: @escaping (() -> Void), completionHandler: @escaping ((String?, Error?) -> Void)) {
        // 1. Create constants.
        guard let url = URL(string: factURLString) else {
            logFactDataError { error in
                completionHandler(nil, error)
            }
            return
        }
        let urlSession = URLSession(configuration: .default)
        let request = createFactGeneratorHTTPRequest(with: url)
        // 2. Call the "did begin" handler.
        didBeginHandler()
        // 3. Create the data task with the fact URL.
        let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
            // 4. If an HTTP response is returned and its code isn't within the 2xx range, log it as an error.
            if let httpResponse = response as? HTTPURLResponse, httpResponse.isUnsuccessful {
                httpResponse.logAsError {
                    error in
                    completionHandler(nil, error)
                }
            }
            // 5. Log any errors.
            else if let error = error {
                completionHandler(nil, error)
                return
            } else {
                // 6. Make sure we can get the fact text. If we can't, an error is logged.
                guard let factText = parseJSON(data: data) else {
                    logFactDataError { error in
                        completionHandler(nil, error)
                    }
                    return
                }
                // 7. Screen the fact to make sure it doesn't contain inappropriate words. If we get an error or an HTTP response with a code that's not in the 2xx range, log an error. If we get a fact, we know the fact is safe and we can display it. If we get nothing, keep trying to generate a fact until we get a safe one. Once a safe fact is generated, give it to the view.
                screenFact(fact: factText) { fact, error in
                    if let error = error {
                        completionHandler(nil, error)
                    } else if let fact = fact {
                        if fact.isEmpty {
                            logNoTextError {
                                error in
                                completionHandler(nil, error)
                            }
                        } else {
                            completionHandler(fact, nil)
                        }
                    } else {
                        generateRandomFact(didBeginHandler: didBeginHandler, completionHandler: completionHandler)
                    }
                }
            }
        }
        // To start a URLSessionDataTask, we resume it.
        dataTask.resume()
    }
    
    // This method creates the fact generator URL request.
    func createFactGeneratorHTTPRequest(with url: URL) -> URLRequest {
        // 1. Create the URL request.
        var request = URLRequest(url: url)
        // 2. Specify the type of content to give back.
        request.setValue(jsonContentType, forHTTPHeaderField: "Accept")
        // 3. Return the created request.
        return request
    }
    
    // This method parses the JSON data returned by the fact generator web API and creates a GeneratedFact object from it, returning the resulting fact text String.
    func parseJSON(data: Data?) -> String? {
        // 1. If data is nil, log an error.
        guard let data = data else {
            return nil
        }
        // 2. Try to decode the JSON data to create a GeneratedFact object, and get the text from it, correcting punctuation as necessary. If decoding fails, log an error.
        let decoder = JSONDecoder()
        do {
            // Since we're using a type name, not an instance of that type, we use TypeName.self instead of TypeName().
            let factObject = try decoder.decode(GeneratedFact.self, from: data)
            return correctedFactText(factObject.text)
        } catch {
            return nil
        }
    }
    
    // MARK: - Fact Text Correction
    
    // This method replaces incorrect characters in the generated fact text.
    func correctedFactText(_ fact: String) -> String {
        // Replace incorrect characters.
        let correctedFact = fact.replacingOccurrences(of: "`", with: "'")
        return correctedFact
    }
    
    // MARK: - Inappropriate Words Checker
    
    // This method screens a fact to make sure it doesn't contain inappropriate words. If it does, fact generation is retried.
    func screenFact(fact: String, completionHandler: @escaping ((String?, Error?) -> Void)) {
        // 1. Create constants.
        guard let url = URL(string: inappropriateWordsCheckerURLString) else {
            completionHandler(nil, nil)
            return }
        let urlSession = URLSession(configuration: .default)
        // 2. Create the URL request.
        guard let request = createInappropriateWordsCheckerHTTPRequest(with: url, toScreenFact: fact) else {
            completionHandler(nil, nil)
            return
        }
        // 3. Create the data task with the inappropriate words checker URL, handling errors and HTTP responses just as we did in generateRandomFact(didBeginHandler:completionHandler:) above.
        let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
            if let error = error {
                completionHandler(nil, error)
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.isUnsuccessful {
                httpResponse.logAsError { error in
                    completionHandler(nil, error)
                }
            }
            let factIsInappropriate = parseFilterJSON(data: data)
            if !factIsInappropriate {
                completionHandler(fact, nil)
            } else {
                completionHandler(nil, nil)
            }
        }
        dataTask.resume()
    }
    
    // This method creates the inappropriate words checker URL request.
    func createInappropriateWordsCheckerHTTPRequest(with url: URL, toScreenFact fact: String) -> URLRequest? {
        // 1. Create the URL request.
        var request = URLRequest(url: url)
        // 2. Specify the type of content to give back.
        request.setValue(jsonContentType, forHTTPHeaderField: "Content-Type")
        // 3. Specify the data model that you want to send.
        let body = ["content": fact]
        // 4. Try to convert model to JSON data and return the created request. If conversion fails, log an error.
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [.fragmentsAllowed])
            request.httpMethod = "POST"
            request.httpBody = jsonData
            return request
        } catch {
            return nil
        }
    }
    
    // This method parses the JSON data returned by the inappropriate words checker web API and creates an InappropriateWordsCheckerData object from it, returning the resulting Bool indicating whether the fact contains inappropriate words.
    func parseFilterJSON(data: Data?) -> Bool {
        // 1. If data is nil, be on the safe side and treat the fact as inappropriate.
        guard let data = data else {
            return true
        }
        // 2. Try to decode the JSON data to create an InappropriateWordsCheckerData object, and get whether the fact is inappropriate from it, returning the fact if it's appropriate. If decoding fails, be on the safe side and treat the fact as inappropriate.
        let decoder = JSONDecoder()
        do {
            let factObject = try decoder.decode(InappropriateWordsCheckerData.self, from: data)
            return factObject.containsInappropriateWords
        } catch {
            return true
        }
    }
    
}
