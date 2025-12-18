//
//  FactGenerator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/21/22.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

// Handles HTTP requests to get random facts and screen them for inappropriate words via web APIs.
struct FactGenerator {
    
    // MARK: - Properties - Result Type Aliases
    
    // A Result is made up of 2 types: Success (can be anything) and Error (must conform to Error). These type aliases simplify the type names.

    // The type of fact generator JSON (JavaScript Object Notation) parsing results. Success is a String containing the fact.
    typealias FactGeneratorJSONParsingResult = Result<String, Error>

    // The type of inappropriate words checker JSON parsing results. Success is a Bool indicating whether the fact contains inappropriate words.
    typealias InappropriateWordsCheckerJSONParsingResult = Result<Bool, Error>

    // The type of inappropriate words checker HTTP request results. Success is the URL request.
    typealias InappropriateWordsCheckerHTTPRequestResult = Result<URLRequest, Error>
    
    // MARK: - Properties - Strings

    // Specifies that the fact generator and inappropriate words checker APIs should return JSON data.
    /* Common HTTP Content Types include:
    * application/json (JSON data)
    * text/plain (plain text)
    * application/xml (XML data)
    * application/x-www-form-urlencoded (form data)
    * multipart/form-data (for file uploads)
     */
    let httpRequestContentType: String = "application/json"

    // The name of the random facts API, which is its base URL.
    let randomFactsAPIName: String = "uselessfacts.jsph.pl"

    // The URL of the random facts API.
    var factURLString: String {
        // 1. The scheme specifies the application layer protocol used to access the resource. In this case, it's "https" (HyperText Transfer Protocol Secure), used for web traffic. The "s" in HTTPS indicates that the data transferred between the app (client) and the web API (server) is encrypted for security. This is not to be confused with presentation layer protocols like SSL (Secure Sockets Layer) or TLS (Transport Layer Security), which are used to secure the connection between the client and server, transport layer protocols like TCP (Transmission Control Protocol) or UDP (User Datagram Protocol), which are used to transmit data over the network, or network layer protocols like IP (Internet Protocol), which are used to route data between devices on a network. The API requests in this app use some of these protocols under the hood.
        /*
        HTTPS is on layer 7 of the OSI (Open Systems Interconnection) model, the application layer, which is the topmost layer. The OSI model is a conceptual framework used to understand how different networking protocols interact with each other. The OSI model consists of 7 layers:
         1. Physical: Hardware and transmission of raw bits (e.g., cables, switches, Wi-Fi radio hardware). In RandoFacto, this is the device’s antennas, radios, and cabling that carry the bits used by your URLSession requests.
         2. Data Link: Node-to-node data transfer, framing, and error detection/correction (e.g., Ethernet, Wi‑Fi protocol). In RandoFacto, this is the Wi‑Fi or cellular link layer that frames packets for the local network your device is on.
         3. Network: Routing and forwarding of data between devices (e.g., IP). In RandoFacto, IP routes your requests to the random fact and inappropriate words checker servers across the internet and returns responses.
         4. Transport: Reliable or unreliable data transfer, segmentation, and flow control (e.g., TCP, UDP). In RandoFacto, TCP provides reliable delivery for HTTPS requests made by URLSession.
         5. Session: Establishment, management, and termination of connections (e.g., session tokens, RPC, NetBIOS). In RandoFacto, TLS sessions are negotiated and maintained so the app can securely exchange HTTP messages.
         6. Presentation: Translation, encryption, and compression (e.g., SSL/TLS, MIME types, character encoding). In RandoFacto, TLS handles encryption/decryption, and Content-Type and Accept headers describe JSON encoding for request/response bodies.
         7. Application: Application-specific protocols and interface for end-users (e.g., HTTP/HTTPS, SMTP, FTP). In RandoFacto, URLSession performs HTTPS GET/POST requests, sends/receives JSON, and FactGenerator's code parses it into Swift types.
        Layer 2 is the physical layer, the hardware which connects the device running RandoFacto to the internet (e.g., the Wi‑Fi radio in a MacBook or iPhone), and layer 1 is how the data is transmitted over the internet (usually very fast pulses of light through fiber optic cables).
        */
        let scheme = "https"
        // 2. The domain and subdomain are the main parts of the URL that identify the server where the resource is located. In this case, the domain is "jsph.pl" and the subdomain is "uselessfacts". "jsph.pl" in this case stands for Joseph Paul, the creator of this API and others (usually "pl" refers to a website in Poland). Each of his API URLs has a different subdomain in the same "jsph.pl" domain.
        let subdomainAndDomain = randomFactsAPIName
        // 3. The path indicates the specific resource or location on the server that the client (in this case RandoFacto) is requesting. In this URL, the path is "/api/vX/facts/random", where X represents the API version.
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
        // This URL is much simpler than the fact generator one above since it doesn't need query parameters.
        let scheme = "https"
        let subdomainAndDomain = "language-checker.vercel.app"
        let languageCheckerPath = "api/check-language"
        let urlString = "\(scheme)://\(subdomainAndDomain)/\(languageCheckerPath)"
        return urlString
    }

    // The name of the JSON property which stores the fact to be screened.
    let factJSONPropertyName: String = "content"

    // MARK: - Properties - Integers

    // The major version of the random facts API.
    let randomFactsAPIVersion: Int = 2

    // MARK: - Properties - Time Intervals

    // The timeout interval of URL requests, which determines the maximum number of seconds they can try to run before a "request timed out" error is thrown if unsuccessful.
    #if(DEBUG)
    // Allow this to be changed in in-development (internal) builds…
    @AppStorage(UserDefaults.KeyNames.urlRequestTimeoutInterval)
    #endif
    // …but not final (release) builds.
    var urlRequestTimeoutInterval: TimeInterval = defaultURLRequestTimeoutInterval
    
    // MARK: - Properties - Errors

    // The error logged when fact data can't be retrieved or decoded (e.g. a Result returns a Failure).
    let factDataError: NSError = NSError(domain: FactGenerator.ErrorDomain.failedToGetData.rawValue, code: FactGenerator.ErrorCode.failedToGetData.rawValue)

    // The error logged when a fact doesn't contain text.
    let noTextError: NSError = NSError(domain: ErrorDomain.noText.rawValue, code: ErrorCode.noText.rawValue)

    // MARK: - Fact Generation
    
    // This method uses a random facts web API which returns JSON data to generate a random fact.
    func generateRandomFact(factGenerationDidBeginHandler: @escaping (() -> Void), completionHandler: @escaping ((String?, Error?) -> Void)) {
        // 1. Call the "did begin" handler.
        factGenerationDidBeginHandler()
        // 2. Create the URL, URL request, and URL session.
        guard let url = URL(string: factURLString) else {
            completionHandler(nil, factDataError)
            return
        }
        let urlRequest = createFactGeneratorHTTPRequest(with: url)
        let urlSession = URLSession(configuration: .default)
        // 3. Create the data task with the fact URL and handle the request.
        let dataTask = urlSession.dataTask(with: urlRequest) { [self] data, response, error in
            handleFactGenerationDataTaskResult(factGenerationDidBeginHandler: factGenerationDidBeginHandler, data: data, response: response, error: error, completionHandler: completionHandler)
        }
        // 4. To start a URLSessionDataTask, we resume it.
        dataTask.resume()
    }

    // This method creates the fact generator HTTP request.
    func createFactGeneratorHTTPRequest(with url: URL) -> URLRequest {
        // 1. Create the URL request.
        var request = URLRequest(url: url)
        // 2. Specify the HTTP method and the type of content to give back. For this HTTP request, it's optional.
        /*
        Common HTTP methods include:
        * GET: Retrieve data from the server (reads, does not modify).
        * POST: Submit new data to the server (creates new resources, can have a body).
        * PUT: Replace an existing resource with new data (full update, idempotent).
        * PATCH: Partially update an existing resource (partial update, idempotent).
        * DELETE: Remove a resource from the server.
        * HEAD: Same as GET but returns only headers, not the body.
        * OPTIONS: Describe the communication options for the resource.
        * TRACE: Echoes the received request for diagnostic purposes.
        * CONNECT: Establish a tunnel to the server (usually for SSL/TLS).
        GET is used here to request data from the server.
        */
        request.httpMethod = URLRequest.HTTPMethod.get
        /* Common HTTP header fields include:
        * Accept: Media types the client is willing to receive. In RandoFacto, the fact generation URL request uses this to tell the random facts server that the app (client) can accept JSON data.
        * Content-Type: Media type of the body sent to the server. In RandoFacto, the inappropriate words checker URL request uses this to tell the inappropriate words checker server to receive JSON data.
        * Authorization: Credentials for authentication. This isn't used in fact generation.
        * User-Agent: Information about the client software. This isn't used in fact generation.
        * Cache-Control: Options to control how long resources are cached (stored on the device) and whether they need to be validated with the server before using the cached copy, and whether to store it only in memory, or to prevent caching. This isn't used in fact generation.
         * Cookie: Whether to send stored cookies (website data) with an HTTP request. This isn't used in fact generation.
         */
        request.setValue(httpRequestContentType, forHTTPHeaderField: URLRequest.HTTPHeaderField.accept)
        // 3. Set the timeout interval for the URL request, after which an error will be thrown if the request can't complete.
        request.timeoutInterval = urlRequestTimeoutInterval
        // 4. Return the created request.
        return request
    }

    // This method handles the fact generation data task result.
    func handleFactGenerationDataTaskResult(factGenerationDidBeginHandler: @escaping (() -> Void), data: Data?, response: URLResponse?, error: Error?, completionHandler: @escaping ((String?, Error?) -> Void)) {
        // 1. If an HTTP response is returned and its code isn't within the 2xx (success) range, it's an error, so log it.
        if let httpResponse = response as? HTTPURLResponse, let httpResponseError = httpResponse.error {
                completionHandler(nil, httpResponseError)
        }
        // 2. If an error that isn't an HTTP response code occurs, log it.
        else if let error = error {
            completionHandler(nil, error)
        } else {
            // 3. Make sure we can get the fact text. If we can't, an error is logged.
            let jsonParsingResult = parseFactDataJSON(data: data)
            // With the Result generic type, we can use a switch statement to handle the result based on whether it's a success (of the desired type) or a failure (of any type that conforms to the Error protocol, including Error itself).
            switch jsonParsingResult {
            case .success(let factText):
                // 4. Screen the fact to make sure it doesn't contain inappropriate words. If we get an error or an HTTP response with a code that's not in the 2xx range, log an error. If we get a fact, we know the fact is safe and we can display it. If we get nothing, keep trying to generate a fact until we get a safe one. Once a safe fact is generated, pass it to the completion handler.
                screenFact(fact: factText) { fact, error in
                    handleFactScreeningResult(factGenerationDidBeginHandler: factGenerationDidBeginHandler, fact: fact, error: error, completionHandler: completionHandler)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
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
        // 1. Replace incorrect characters.
        var correctedFact = fact.replacingOccurrences(of: "`", with: "'")
        // 2. Remove any leading or trailing spaces.
        if correctedFact.last == " " {
            correctedFact = String(correctedFact.dropLast())
        }
        if correctedFact.first == " " {
            correctedFact = String(correctedFact.dropFirst())
        }
        // 3. Return the corrected fact text.
        return correctedFact
    }
    
    // MARK: - Inappropriate Words Checker
    
    // This method screens a fact to make sure it doesn't contain inappropriate words. If it does, fact generation is retried. While early builds of the initial release, 2023.12 (November 2022-December 2023), displayed messages to the user during the screening process or if an inappropriate fact was returned, we decided to not make the presence of an inappropriate words checker visible to the user, and it's not mentioned anywhere in the app's documentation or info.
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
            // 3. Create the data task with the inappropriate words checker URL, handling errors and HTTP responses just as we did in generateRandomFact(factGenerationDidBeginHandler:completionHandler:) above.
            let dataTask = urlSession.dataTask(with: request) { [self] data, response, error in
                handleInappropriateWordsCheckerDataTaskResult(fact: fact, data: data, response: response, error: error, completionHandler: completionHandler)
            }
            dataTask.resume()
        case .failure(let error):
            completionHandler(nil, error)
        }
    }
    
    // This method creates the inappropriate words checker HTTP request. Unlike the fact generator HTTP request, this one can potentially fail since it involves converting data to JSON to send to a server, so we don't simply return a URLRequest.
    func createInappropriateWordsCheckerHTTPRequest(with url: URL, toScreenFact fact: String) -> InappropriateWordsCheckerHTTPRequestResult {
        // 1. Create the URL request.
        var request = URLRequest(url: url)
        // 2. Specify the HTTP method and the type of content to send (POST). For this HTTP request, it's required.
        // POST is used here to send data to the server. In this case, data isn't stored on the server as POST might imply.
        request.httpMethod = URLRequest.HTTPMethod.post
        request.setValue(httpRequestContentType, forHTTPHeaderField: URLRequest.HTTPHeaderField.contentType)
        // 3. Set the timeout interval for the URL request, after which an error will be thrown if the request can't complete.
        request.timeoutInterval = urlRequestTimeoutInterval
        // 4. Specify the data model to send.
        let body = [factJSONPropertyName : fact]
        let jsonWritingOptions: JSONSerialization.WritingOptions = [.fragmentsAllowed]
        // 5. Try to convert body to JSON data and return the created request. If conversion fails, log an error.
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: jsonWritingOptions)
            request.httpBody = jsonData
            return .success(request)
        } catch {
            return .failure(error)
        }
    }

    // This method handles the inappropriate words checker HTTP request for the given fact.
    func handleInappropriateWordsCheckerDataTaskResult(fact: String, data: Data?, response: URLResponse?, error: Error?, completionHandler: ((String?, Error?) -> Void)) {
        // 1. If an HTTP response is returned and its code isn't within the 2xx (success) range, it's an error, so log it.
        if let httpResponse = response as? HTTPURLResponse, let httpResponseError = httpResponse.error {
            completionHandler(nil, httpResponseError)
        } else
        // 2. If an error that isn't an HTTP response code occurs, log it.
        if let error = error {
            completionHandler(nil, error)
        } else {
            // 3. Make sure we can get whether the fact contains inappropriate words. If we can't, an error is logged.
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

    // This method handles the fact screening result.
    func handleFactScreeningResult(factGenerationDidBeginHandler: @escaping (() -> Void), fact: String?, error: Error?, completionHandler: @escaping ((String?, Error?) -> Void)) {
        // 1. If an error occurs during screening, log it.
        if let error = error {
            completionHandler(nil, error)
        } else if let fact = fact {
            // 2. If a fact is returned, pass it to the completion handler. If it doesn't contain text, log an error.
            if fact.isEmpty {
               completionHandler(nil, noTextError)
            } else {
                completionHandler(fact, nil)
            }
        } else {
            // 3. If no fact or error was passed to this method (a fact was screened and found to be inappropriate), retry fact generation.
            generateRandomFact(factGenerationDidBeginHandler: factGenerationDidBeginHandler, completionHandler: completionHandler)
        }
    }

}
