//
//  FactGenerator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct FactGenerator {
    
    // MARK: - Properties - Result Type Aliases
    
    // A Result is made up of 2 types, Success (can be anything) and Error (must conform to Error). These type aliases simplify the type names.
    
    typealias FactGeneratorJSONParsingResult = Result<String, Error>
    
    typealias InappropriateWordsCheckerJSONParsingResult = Result<Bool, Error>
    
    typealias InappropriateWordsCheckerHTTPRequestResult = Result<URLRequest, Error>
    
    // MARK: - Properties - HTTP Request Content Type
    
    // Specifies that the fact generator and inappropriate words checker APIs should return JSON data.
    let httpRequestContentType = "application/json"
    
    // The name of the random facts API, which is its base URL.
    let randomFactsAPIName = "uselessfacts.jsph.pl"
    
    // The version of the random facts API.
    let randomFactsAPIVersion = 2
    
    // MARK: - Properties - URLs
    
    // The URL of the random facts API.
    var factURLString: String {
        // 1. The scheme specifies the protocol used to access the resource. In this case, it's "https" (Hypertext Transfer Protocol Secure). This indicates that the data transferred between the app (client) and the web API (server) is encrypted for security.
        let scheme = "https"
        // 2. The domain and subdomain are the main parts of the URL that identify the server where the resource is located. In this case, the domain is "jsph.pl" and the subdomain is "uselessfacts". "jsph.pl" in this case stands for Joeseph Paul, the creator of this API and others (usually "pl" means a website in Poland).
        let subdomainAndDomain = randomFactsAPIName
        // 3. The path indicates the specific resource or location on the server that the client (RandoFacto) is requesting. In this URL, the path is "/api/vX/facts/random", where X represents the API version.
        let randomFactPath = "api/v\(randomFactsAPIVersion)/facts/random"
        // 4. Query parameters are additional information provided in the URL to modify the request. They follow a question mark (?) and are separated by ampersands (&). In this URL, there is one query parameter, "language=en", indicating that the client is requesting a fact in English. Sometimes, parts of the request are modified by setting one or more HTTP header fields.
        let lowercaseLanguageCode = "en"
        let languageQueryParameter = "language=\(lowercaseLanguageCode)"
        // 5. Put the components together to create the full URL string to return. In this case, it's "https://uselessfacts.jsph.pl/api/vX/facts/random?language=en", where X represents the API version.
        let urlString = "\(scheme)://\(subdomainAndDomain)/\(randomFactPath)?\(languageQueryParameter)"
        return urlString
    }
    
    // The URL of the inappropriate words checker API.
    var inappropriateWordsCheckerURLString: String {
        // This URL is much simpler than the fact generator one above.
        let scheme = "https"
        let subdomainAndDomain = "language-checker.vercel.app"
        let languageCheckerPath = "api/check-language"
        let urlString = "\(scheme)://\(subdomainAndDomain)/\(languageCheckerPath)"
        return urlString
    }
    
    // MARK: - Properties - URL Request Timeout Interval
    
    // The timeout interval of URL requests, which determines the maximum number of seconds they can try to run before a "request timed out" error is thrown if unsuccessful.
    #if(DEBUG)
    @AppStorage("urlRequestTimeoutInterval") 
    #endif
    var urlRequestTimeoutInterval: TimeInterval = defaultURLRequestTimeoutInterval
    
    // MARK: - Properties - Errors
    
    // The error logged when a Result returns a Failure.
    let factDataError = NSError(domain: FactGenerator.ErrorDomain.failedToGetData.rawValue, code: FactGenerator.ErrorCode.failedToGetData.rawValue)
    
    // MARK: - Fact Generation
    
    // This method uses a random facts web API which returns JSON data to generate a random fact.
    func generateRandomFact(didBeginHandler: @escaping (() -> Void), completionHandler: @escaping ((String?, Error?) -> Void)) {
        // 1. Call the "did begin" handler.
        didBeginHandler()
        // 2. Create the URL, URL request, and URL session.
        guard let url = URL(string: factURLString) else {
                completionHandler(nil, logFactDataError())
            return
        }
        let urlRequest = createFactGeneratorHTTPRequest(with: url)
        let urlSession = URLSession(configuration: .default)
        // 3. Create the data task with the fact URL and handle the request.
        let dataTask = urlSession.dataTask(with: urlRequest) { [self] data, response, error in
            handleFactGenerationDataTaskResult(didBeginHandler: didBeginHandler, data: data, response: response, error: error, completionHandler: completionHandler)
        }
        // To start a URLSessionDataTask, we resume it.
        dataTask.resume()
    }
    
    // This method handles the fact generation data task result.
    func handleFactGenerationDataTaskResult(didBeginHandler: @escaping (() -> Void), data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping ((String?, Error?) -> Void)) {
        // 1. If an HTTP response is returned and its code isn't within the 2xx range, log it as an error.
        if let httpResponse = response as? HTTPURLResponse, httpResponse.isUnsuccessful {
                completionHandler(nil, httpResponse.logAsError())
        }
        // 2. Log any errors.
        else if let error = error {
            completionHandler(nil, error)
            return
        } else {
            // 3. Make sure we can get the fact text. If we can't, an error is logged.
            let jsonParsingResult = parseFactDataJSON(data: data)
            // With the Result generic type, we can use a switch statement to handle the result based on whether it's a success or a failure.
            switch jsonParsingResult {
            case .success(let factText):
                // 4. Screen the fact to make sure it doesn't contain inappropriate words. If we get an error or an HTTP response with a code that's not in the 2xx range, log an error. If we get a fact, we know the fact is safe and we can display it. If we get nothing, keep trying to generate a fact until we get a safe one. Once a safe fact is generated, give it to the view.
                screenFact(fact: factText) { fact, error in
                    if let error = error {
                        completionHandler(nil, error)
                    } else if let fact = fact {
                        if fact.isEmpty {
                           completionHandler(nil, logNoTextError())
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
    
    // This method creates the fact generator HTTP request.
    func createFactGeneratorHTTPRequest(with url: URL) -> URLRequest {
        // 1. Create the URL request.
        var request = URLRequest(url: url)
        // 2. Specify the HTTP method and the type of content to give back. For this HTTP request, it's optional.
        request.httpMethod = URLRequest.HTTPMethod.get
        request.setValue(httpRequestContentType, forHTTPHeaderField: URLRequest.HTTPHeaderField.accept)
        // 3. Set the timeout interval for the URL request, after which an error will be thrown if the request can't complete.
        request.timeoutInterval = urlRequestTimeoutInterval
        // 4. Return the created request.
        return request
    }
    
    // This method parses the JSON data returned by the fact generator web API and creates a GeneratedFact object from it, returning the resulting fact text String if successful or an Error if unsuccessful.
    func parseFactDataJSON(data: Data?) -> FactGeneratorJSONParsingResult {
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
                handleInappropriateWordsCheckerDataTaskResult(fact: fact, data: data, response: response, error: error, completionHandler: completionHandler)
            }
            dataTask.resume()
        case .failure(let error):
            completionHandler(nil, error)
        }
    }
    
    // This method handles the inappropriate words checker HTTP request for the given fact.
    func handleInappropriateWordsCheckerDataTaskResult(fact: String, data: Data?, response: URLResponse?, error: Error?, completionHandler: ((String?, Error?) -> Void)) {
        if let error = error {
            completionHandler(nil, error)
        }
        if let httpResponse = response as? HTTPURLResponse, httpResponse.isUnsuccessful {
            completionHandler(nil, httpResponse.logAsError())
        }
        let jsonParsingResult = parseInappropriateWordsCheckerJSON(data: data)
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
    
    // This method creates the inappropriate words checker HTTP request.
    func createInappropriateWordsCheckerHTTPRequest(with url: URL, toScreenFact fact: String) -> InappropriateWordsCheckerHTTPRequestResult {
        // 1. Create the URL request.
        var request = URLRequest(url: url)
        // 2. Specify the HTTP method and the type of content to give back. For this HTTP request, it's required.
        request.httpMethod = URLRequest.HTTPMethod.post
        request.setValue(httpRequestContentType, forHTTPHeaderField: URLRequest.HTTPHeaderField.contentType)
        // 3. Set the timeout interval for the URL request, after which an error will be thrown if the request can't complete.
        request.timeoutInterval = urlRequestTimeoutInterval
        // 4. Specify the data model that you want to send.
        let body = ["content": fact]
        // 5. Try to convert body to JSON data and return the created request. If conversion fails, log an error.
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [.fragmentsAllowed])
            request.httpBody = jsonData
            return .success(request)
        } catch {
            return .failure(error)
        }
    }
    
    // This method parses the JSON data returned by the inappropriate words checker web API and creates an InappropriateWordsCheckerData object from it, returning the resulting Bool indicating whether the fact contains inappropriate words.
    func parseInappropriateWordsCheckerJSON(data: Data?) -> InappropriateWordsCheckerJSONParsingResult {
        // 1. If data is nil, log an error.
        guard let data = data else {
            return .failure(factDataError)
        }
        // 2. Try to decode the JSON data to create an InappropriateWordsCheckerData object, and get whether the fact is inappropriate from it, returning the fact if it's appropriate. If decoding fails, log an error.
        let decoder = JSONDecoder()
        do {
            let factObject = try decoder.decode(InappropriateWordsCheckerData.self, from: data)
            return .success(factObject.containsInappropriateWords)
        } catch {
            return .failure(error)
        }
    }
    
}
