//
//  FactGenerator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import Foundation

struct FactGenerator {
    
    // MARK: - Properties - Type Aliases
    
    typealias FactGeneratorResultType = Result<String, Error>
    
    typealias InappropriateWordsCheckerResultType = Result<Bool, Error>
    
    typealias InappropriateWordsCheckerHTTPRequestResultType = Result<URLRequest, Error>
    
    // MARK: - Properties - Content Type
    
    // Specifies that the fact generator and inappropriate words checker APIs should return JSON data.
    let jsonContentType = "application/json"
    
    // MARK: - Properties - URLs
    
    // The URL of the random facts API.
    private var factURLString: String {
        // 1. The scheme specifies the protocol used to access the resource. In this case, it's "https" (Hypertext Transfer Protocol Secure). This indicates that the data transferred between the app and the server is encrypted for security.
        let scheme = "https"
        // 2. The domain and subdomain are the main parts of the URL that identify the server where the resource is located. In this case, the domain is "jsph.pl" and the subdomain is "uselessfacts". "jsph.pl" in this case stands for Joeseph Paul, the creator of this API and others (usually "pl" means a website in Poland).
        let subdomain = "uselessfacts"
        let domain = "jsph.pl"
        // 3. The path indicates the specific resource or location on the server that the client (RandoFacto) is requesting. In this URL, the path is "/api/vX/facts/random", where X represents the API version.
        let apiVersion = 2
        let randomFactPath = "api/v\(apiVersion)/facts/random"
        // 4. Query parameters are additional information provided in the URL to modify the request. They follow a question mark (?) and are separated by ampersands (&). In this URL, there is one query parameter, "language=en", indicating that the client is requesting a fact in English. Sometimes, parts of the request are modified by setting one or more HTTP header fields.
        let lowercaseLanguageCode = "en"
        let languageQueryParameter = "language=\(lowercaseLanguageCode)"
        // 5. Put the components together to create the full URL string to return.
        let urlString = "\(scheme)://\(subdomain).\(domain)/\(randomFactPath)?\(languageQueryParameter)"
        return urlString
    }
    
    // The URL of the inappropriate words checker API.
    private var inappropriateWordsCheckerURLString: String {
        // This URL is much simpler than the fact generator one above.
        let scheme = "https"
        let subdomain = "language-checker"
        let domain = "vercel.app"
        let languageCheckerPath = "api/check-language"
        let urlString = "\(scheme)://\(subdomain).\(domain)/\(languageCheckerPath)"
        return urlString
    }
    
    // MARK: - Properties - URL Request Timeout Interval
    
    // The timeout interval of URL requests, which determines the maximum number of seconds they can try to run before a "request timed out" error is thrown if unsuccessful.
    let urlRequestTimeoutInterval: TimeInterval = 5
    
    // MARK: - Properties - Errors
    
    let factDataError = NSError(domain: FactGenerator.ErrorDomain.failedToGetData.rawValue, code: FactGenerator.ErrorCode.failedToGetData.rawValue)
    
    // MARK: - Fact Generation
    
    // This method uses a random facts web API which returns JSON data to generate a random fact.
    func generateRandomFact(didBeginHandler: @escaping (() -> Void), completionHandler: @escaping ((String?, Error?) -> Void)) {
        // 1. Call the "did begin" handler.
        didBeginHandler()
        // 2. Create the URL, URL request, and URL session.
        guard let url = URL(string: factURLString) else {
            logFactDataError { error in
                completionHandler(nil, error)
            }
            return
        }
        let urlRequest = createFactGeneratorHTTPRequest(with: url)
        let urlSession = URLSession(configuration: .default)
        // 3. Create the data task with the fact URL.
        let dataTask = urlSession.dataTask(with: urlRequest) { [self] data, response, error in
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
                let jsonParsingResult = parseJSON(data: data)
                switch jsonParsingResult {
                case .success(let factText):
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
                case .failure(let error):
                    completionHandler(nil, error)
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
        // 2. Specify the HTTP method and the type of content to give back.
        request.httpMethod = "GET"
        request.setValue(jsonContentType, forHTTPHeaderField: "Accept")
        // 3. Set the timeout interval for the URL request, after which an error will be thrown if the request can't complete.
        request.timeoutInterval = urlRequestTimeoutInterval
        // 4. Return the created request.
        return request
    }
    
    // This method parses the JSON data returned by the fact generator web API and creates a GeneratedFact object from it, returning the resulting fact text String.
    func parseJSON(data: Data?) -> FactGeneratorResultType {
        // 1. If data is nil, log an error.
        guard let data = data else {
            return .failure(factDataError)
        }
        // 2. Try to decode the JSON data to create a GeneratedFact object, and get the text from it, correcting punctuation as necessary. If decoding fails, log an error.
        let decoder = JSONDecoder()
        do {
            // Since we're using a type name, not an instance of that type, we use TypeName.self instead of TypeName().
            let factObject = try decoder.decode(GeneratedFact.self, from: data)
            return .success(correctedFactText(factObject.text))
        } catch {
            return .failure(error)
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
        // 1. Create the URL and URL session.
        guard let url = URL(string: inappropriateWordsCheckerURLString) else {
            completionHandler(nil, nil)
            return }
        let urlSession = URLSession(configuration: .default)
        // 2. Create the URL request.
        let httpRequestResult = createInappropriateWordsCheckerHTTPRequest(with: url, toScreenFact: fact)
        switch httpRequestResult {
        case .success(let request):
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
                let jsonParsingResult = parseFilterJSON(data: data)
                switch jsonParsingResult {
                case .success(let factIsInappropriate):
                    if !factIsInappropriate {
                        completionHandler(fact, nil)
                    } else {
                        completionHandler(nil, nil)
                    }
                case .failure(let error):
                    completionHandler(nil, error)
                }
            }
            dataTask.resume()
        case .failure(let error):
            completionHandler(nil, error)
        }
    }
    
    // This method creates the inappropriate words checker URL request.
    func createInappropriateWordsCheckerHTTPRequest(with url: URL, toScreenFact fact: String) -> InappropriateWordsCheckerHTTPRequestResultType {
        // 1. Create the URL request.
        var request = URLRequest(url: url)
        // 2. Specify the HTTP method and the type of content to give back.
        request.httpMethod = "POST"
        request.setValue(jsonContentType, forHTTPHeaderField: "Content-Type")
        // 3. Set the timeout interval for the URL request, after which an error will be thrown if the request can't complete.
        request.timeoutInterval = urlRequestTimeoutInterval
        // 4. Specify the data model that you want to send.
        let body = ["content": fact]
        // 5. Try to convert model to JSON data and return the created request. If conversion fails, log an error.
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [.fragmentsAllowed])
            request.httpBody = jsonData
            return .success(request)
        } catch {
            return .failure(error)
        }
    }
    
    // This method parses the JSON data returned by the inappropriate words checker web API and creates an InappropriateWordsCheckerData object from it, returning the resulting Bool indicating whether the fact contains inappropriate words.
    func parseFilterJSON(data: Data?) -> InappropriateWordsCheckerResultType {
        // 1. If data is nil, be on the safe side and treat the fact as inappropriate.
        guard let data = data else {
            return .failure(factDataError)
        }
        // 2. Try to decode the JSON data to create an InappropriateWordsCheckerData object, and get whether the fact is inappropriate from it, returning the fact if it's appropriate. If decoding fails, be on the safe side and treat the fact as inappropriate.
        let decoder = JSONDecoder()
        do {
            let factObject = try decoder.decode(InappropriateWordsCheckerData.self, from: data)
            return .success(factObject.containsInappropriateWords)
        } catch {
            return .failure(error)
        }
    }
    
}
