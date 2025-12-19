//
//  PasswordStrengthMeter.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/9/25.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

struct PasswordStrengthMeter: View {

    // MARK: - Properties - Strings

    @Binding var password: String

    // MARK: - Properties - Evaluation

    private var evaluation: PasswordEvaluator.Evaluation {
        PasswordEvaluator.evaluate(password)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                PasswordStrengthBar(fraction: evaluation.strength.scoreFraction, color: evaluation.strength.color)
                .frame(height: 20)
                .accessibilityLabel(evaluation.strength.label)
                HStack {
                    Spacer()
                    Text(evaluation.strength.label)
                        .font(.subheadline).bold()
                        .foregroundStyle(evaluation.strength == .veryStrong ? .black : .primary)
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.25), value: evaluation.strength)
                        .accessibilityHidden(true)
                }
            }
                HStack(spacing: 6) {
                    Image(systemName: PasswordEvaluator.symbol(for: evaluation.strength))
                        .foregroundStyle(evaluation.strength.color)
                        .accessibilityHidden(true)
                    Text(PasswordEvaluator.shortAdvice(for: evaluation.strength))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            if !evaluation.suggestions.isEmpty {
                DisclosureGroup("Suggestions (\(evaluation.suggestions.count))") {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(evaluation.suggestions, id: \.self) { suggestion in
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.right")
                                    .accessibilityHidden(true)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(suggestion)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

}

// MARK: - Preview

#Preview("Very Weak") {
    PasswordStrengthMeter(password: .constant("123"))
}

#Preview("Weak") {
    PasswordStrengthMeter(password: .constant("1Rj4z"))
}

#Preview("Medium") {
    PasswordStrengthMeter(password: .constant("1R4*2zt"))
}

#Preview("Strong") {
    PasswordStrengthMeter(password: .constant("1Rj4*23!qRz"))
}

#Preview("Very Strong") {
    PasswordStrengthMeter(password: .constant("1Rj4*23!qRzt"))
}
