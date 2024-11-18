//
//  PrivacyPolicyButton.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/8/24.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI

struct PrivacyPolicyButton: View {

    // MARK: - Body

    var body: some View {
        Button("Privacy Policy…", systemImage: "hand.raised.circle") {
            showPrivacyPolicy()
        }
    }

    // MARK: - Show Privacy Policy

    func showPrivacyPolicy() {
        let privacyURL = URL(string: "https://techwithtyler20.weebly.com/randofactoprivacypolicy")!
        #if os(macOS)
        NSWorkspace.shared.open(privacyURL)
        #else
        UIApplication.shared.open(privacyURL)
        #endif
    }

}

#Preview {
    PrivacyPolicyButton()
}
