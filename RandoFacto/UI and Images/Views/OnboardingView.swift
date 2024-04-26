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
            Text("Welcome to \(appName!)!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                Text("\(appName!) is a random facts app that gets random facts from \(appStateManager.factGenerator.randomFactsAPIName).")
                Text("Press the speech bubble \(Image(systemName: speechSymbolName)) to have displayed facts read out loud!")
                Text("Create a \(appName!) account in \(Text("Settings>Account").bold()) to save your favorite facts to view offline on all your devices.")
                Text("You can change the fact text size in \(Text("Settings>Display").bold()).")
            }
            .font(.system(size: 18))
            .multilineTextAlignment(.leading)
            Spacer()
            Text("By creating a \(appName!) account, you agree to our [privacy policy](https://techwithtyler20.weebly.com/randofactoprivacypolicy.html).")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Divider()
            Button {
                appStateManager.shouldOnboard = false
                appStateManager.showingOnboarding = false
            } label: {
                Text("Continue")
                    .frame(width: 300)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding()
        .frame(maxWidth: 600, minHeight: 500)
        .interactiveDismissDisabled()
    }
}

#Preview {
    OnboardingView()
        .withPreviewData()
}
