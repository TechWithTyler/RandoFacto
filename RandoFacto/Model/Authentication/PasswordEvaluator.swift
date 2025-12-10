//
//  PasswordEvaluator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/9/25.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

// Processes a password and returns strength and suggestions.
struct PasswordEvaluator {

    // MARK: - Type Aliases

    // The type of a password evaluation.
    typealias Evaluation = (strength: PasswordStrength, suggestions: [String])

    // Defines levels of strength, associated text, and color for the meter.
    enum PasswordStrength: Int, CaseIterable {

        // MARK: - Password Strength Enum Cases

        case veryWeak

        case weak

        case medium

        case strong

        case excellent

        // MARK: - Password Strength Label

        var label: String {
            switch self {
            case .veryWeak: return "Very weak"
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            case .excellent: return "Excellent"
            }
        }

        // MARK: - Password Strength Color

        var color: Color {
            switch self {
            case .veryWeak: return .red
            case .weak: return .orange
            case .medium: return .yellow
            case .strong: return .green.opacity(0.75)
            case .excellent: return .green
            }
        }

        // MARK: - Password Strength Fraction

        var scoreFraction: Double {
            return Double(self.rawValue) / Double(PasswordStrength.allCases.count - 1)
        }

    }

    // MARK: - Evaluate Password

    // This method evaluates password and returns its strength and any suggestions.
    static func evaluate(_ password: String) -> (strength: PasswordStrength, suggestions: [String]) {
        // 1. Get the length of the password.
        let length = password.count
        // 2. Check each character category (e.g. uppercase, lowercase, numbers)
        let lowercaseRegex = "[a-z]"
        let uppercaseRegex = "[A-Z]"
        let digitRegex = "[0-9]"
        let symbolRegex = "[^A-Za-z0-9]"
        let hasLowercase = password.range(of: lowercaseRegex, options: .regularExpression) != nil
        let hasUppercase = password.range(of: uppercaseRegex, options: .regularExpression) != nil
        let hasDigit = password.range(of: digitRegex, options: .regularExpression) != nil
        let hasSymbol = password.range(of: symbolRegex, options: .regularExpression) != nil
        // 3. Score based on variety and length.
        var points = 0
        // Length (1 point if greater than or equal to 8, 2 if greater than or equal to 12)
        if length >= 8 { points += 1 }
        if length >= 12 { points += 1 }
        // Mixure of uppercase and lowercase
        if hasLowercase && hasUppercase { points += 1 }
        // Numbers
        if hasDigit { points += 1 }
        // Symbols
        if hasSymbol { points += 1 }
        // 4. Penalize weak patterns (e.g. 123456 or abcdef).
        let lower = password.lowercased()
        let commonPatterns = [
            "password",
            "1234",
            "123123",
            "123456",
            "qwerty",
            "abcd",
            "abcdef",
            "letmein",
            "1111",
            "pass"
        ]
        let hasCommon = commonPatterns.contains { lower.contains($0) }
        if hasCommon { points = max(0, points - 2) }
        // 5. Clamp the score.
        let clamped = max(0, min(points, 5))
        // 6. Convert score to strength level.
        let index: Int
        switch clamped {
        case 0...1: index = 0
        case 2: index = 1
        case 3: index = 2
        case 4: index = 3
        default: index = 4
        }
        let strength = PasswordStrength(rawValue: index) ?? .veryWeak
        // 7. Build suggestions.
        var suggestions: [String] = []
        if length < 12 { suggestions.append("Use 12+ characters for better security") }
        if !hasUppercase { suggestions.append("Add uppercase letters") }
        if !hasLowercase { suggestions.append("Add lowercase letters") }
        if !hasDigit { suggestions.append("Include digits") }
        if !hasSymbol { suggestions.append("Include symbols like !@#$%") }
        if hasCommon { suggestions.append("Avoid common patterns like \(commonPatterns[3])") }
        return (strength, suggestions)
    }

    // MARK: - Short Descriptive Advice

    static func shortAdvice(for strength: PasswordStrength) -> String {
        switch strength {
        case .veryWeak: return "Too short or predictable"
        case .weak: return "Needs more variety"
        case .medium: return "OK but could improve"
        case .strong: return "Strong — maybe add length"
        case .excellent: return "Excellent strength"
        }
    }

    // MARK: - SF Symbol selection

    static func symbol(for strength: PasswordStrength) -> String {
        switch strength {
        case .veryWeak: return "lock.open.trianglebadge.exclamationmark"
        case .weak: return "exclamationmark.triangle"
        case .medium: return "minus.circle"
        case .strong: return "checkmark.circle"
        case .excellent: return "lock.circle"
        }
    }

}
