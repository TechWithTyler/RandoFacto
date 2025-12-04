//
//  OnboardingView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/19/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

struct OnboardingView: View {

    // MARK: - Properties - App State Manager

    @EnvironmentObject var windowStateManager: WindowStateManager

    // MARK: - Body

    var body: some View {
        VStack {
            Text("Welcome to \(appName!)!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
            ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                    Text("\(appName!) is a random facts app that gets random facts from \(windowStateManager.factGenerator.randomFactsAPIName).")
                    Text("Press the speech bubble \(Image(systemName: speechSymbolName)) to have displayed facts read out loud!")
                    Text("Create a \(appName!) account in \(Text("Settings>Account").bold()) to save your favorite facts to view offline on all your devices.")
                    Text("You can change the fact text size in \(Text("Settings>Display").bold()).")
                }
            }
            .font(.system(size: 18))
            .multilineTextAlignment(.leading)
            Spacer()
            PrivacyPolicyAgreementText()
            Divider()
            Button {
                windowStateManager.shouldOnboard = false
                windowStateManager.showingOnboarding = false
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

// MARK: - Preview

#Preview {
    OnboardingView()
        #if DEBUG
        .withPreviewData()
    #endif
}
