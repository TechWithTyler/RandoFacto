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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PasswordStrengthBar(fraction: evaluation.strength.scoreFraction, color: evaluation.strength.color)
                .frame(height: 12)
                .accessibilityLabel(evaluation.strength.label)
                Spacer(minLength: 12)
                Text(evaluation.strength.label)
                    .font(.subheadline).bold()
                    .foregroundColor(evaluation.strength.color)
            }
                HStack(spacing: 6) {
                    Image(systemName: PasswordEvaluator.symbol(for: evaluation.strength))
                        .foregroundColor(evaluation.strength.color)
                        .accessibilityHidden(true)
                    Text(PasswordEvaluator.shortAdvice(for: evaluation.strength))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            if !evaluation.suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(evaluation.suggestions, id: \.self) { suggestion in
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .accessibilityHidden(true)
                            .font(.caption)
                            .opacity(0.6)
                        Text(suggestion)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                }
            }
        }
        .padding(.vertical, 8)
    }

}

// MARK: - Preview

#Preview {
    PasswordStrengthMeter(password: .constant("ExamplePassword123!"))
}
