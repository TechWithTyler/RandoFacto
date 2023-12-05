import Foundation

/// This class handles the searching of facts.
class FactSearchHandler {
    
    /// Search through the given facts based on the search text.
    /// - Parameters:
    ///   - facts: The array of facts to search through.
    ///   - searchText: The text to search for within the facts.
    /// - Returns: An array of facts that match the search criteria.
    static func searchFacts(facts: [String], searchText: String) -> [String] {
        if searchText.isEmpty {
            return facts
        } else {
            return facts.filter { factText in
                let searchTermRegex = "\\b.*" + NSRegularExpression.escapedPattern(for: searchText) + ".*\\b"                
                let regex = try? NSRegularExpression(pattern: searchTermRegex, options: .caseInsensitive)
                return regex?.firstMatch(in: factText, options: [], range: NSRange(location: 0, length: factText.utf16.count)) != nil
            }
        }
    }
}
