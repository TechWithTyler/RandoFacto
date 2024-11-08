//
//  PrivacyPolicyAgreementText.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 6/3/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct PrivacyPolicyAgreementText: View {
    var body: some View {
        Text("By creating a \(appName!) account, you agree to our [privacy policy](https://techwithtyler20.weebly.com/randofactoprivacypolicy.html).")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }
}

#Preview {
    PrivacyPolicyAgreementText()
}
