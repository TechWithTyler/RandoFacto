//
//  PasswordStrengthBar.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/9/25.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

struct PasswordStrengthBar: View {

    // MARK: - Properties - Doubles

    var fraction: Double // 0.0–1.0 strength fill

    // MARK: - Properties - Colors

    var color: Color

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(Color.primary.opacity(0.08))
                RoundedRectangle(cornerRadius: 6)
                    .frame(width: max(1, CGFloat(fraction) * geo.size.width))
                    .foregroundStyle(color)
                    .animation(.easeInOut(duration: 0.25), value: fraction)
            }
        }
    }

}

// MARK: - Preview

#Preview {
    PasswordStrengthBar(fraction: 0.5, color: .yellow)
}
