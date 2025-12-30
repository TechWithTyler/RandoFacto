//
//  AdvancedSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

struct AdvancedSettingsPageView: View {

    // MARK: - Properties - Objects

    @EnvironmentObject var settingsManager: SettingsManager

    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var errorManager: ErrorManager

    // MARK: - Body

    var body: some View {
        Form {
            Section("Documentation") {
                Button("Help…", systemImage: "questionmark.circle") {
                    showHelp()
                }
                .controlSize(.large)
                PrivacyPolicyButton()
                    .controlSize(.large)
            }
            Section {
                Button(role: .destructive) {
                    settingsManager.showingResetAlert = true
                } label: {
                    Label("RESET ALL SETTINGS…", systemImage: "trash.fill")
#if !os(macOS)
                        .foregroundStyle(.red)
#endif
                }
                .controlSize(.large)
            }
        }
        .formStyle(.grouped)
        // Reset alert
        .alert("Are you sure you REALLY want to reset \(SAAppName)?", isPresented: $settingsManager.showingResetAlert) {
            Button("Cancel", role: .cancel) {
                settingsManager.showingResetAlert = false
            }
            Button("Reset", role: .destructive) {
                settingsManager.resetApp()
            }
        } message: {
            Text("This will reset all settings to default\(authenticationManager.userLoggedIn ? " and log you out of your account" : String()). This can't be undone!")
        }
#if os(macOS)
        .dialogSeverity(.critical)
#endif
    }
    
}

// MARK: - Preview

#Preview {
    AdvancedSettingsPageView()
        #if DEBUG
        .withPreviewData()
    #endif
}
