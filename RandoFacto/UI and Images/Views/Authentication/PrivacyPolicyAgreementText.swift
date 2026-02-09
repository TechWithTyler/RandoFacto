//
//  PrivacyPolicyAgreementText.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 6/3/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsInternals

struct PrivacyPolicyAgreementText: View {

    // MARK: - Body

    var body: some View {
        Text("By creating a \(SABundleName) account, you agree to our [privacy policy](https://techwithtyler20.weebly.com/randofactoprivacypolicy.html).")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Preview

#Preview {
    PrivacyPolicyAgreementText()
}
