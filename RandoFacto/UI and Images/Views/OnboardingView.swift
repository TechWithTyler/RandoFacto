//
//  OnboardingView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/19/24.
//  Copyright © 2024 SheftApps. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        VStack {
            Text("Welcome to RandoFacto!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                Text("RandoFacto is a random facts app that gets random facts from \(appStateManager.factGenerator.factGeneratorAPIName).")
                Text("Press the speech bubble to have displayed facts read out loud!")
                Text("Create a RandoFacto account in Settings to save your favorite facts to view offline on all your devices.")
                Text("You can change the fact text size in Settings.")
            }
            .font(.system(size: 18))
            .multilineTextAlignment(.leading)
            Spacer()
            Text("By using this app, you agree to our [privacy policy](https://techwithtyler20.weebly.com/randofactoprivacypolicy.html).")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Divider()
            Button {
                appStateManager.shouldOnboard = false
                appStateManager.showingOnboarding = false
            } label: {
                Text("Continue")
                    .frame(width: 300)
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: 600, minHeight: 500)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStateManager())
}
