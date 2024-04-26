//
//  AdvancedSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2024 SheftApps. All rights reserved.
//

import SwiftUI

struct AdvancedSettingsPageView: View {

    @EnvironmentObject var appStateManager: AppStateManager

    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var errorManager: ErrorManager

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
                    appStateManager.showingResetAlert = true
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
        .alert("Are you sure you REALLY want to reset \(appName!)?", isPresented: $appStateManager.showingResetAlert) {
            Button("Cancel", role: .cancel) {
                appStateManager.showingResetAlert = false
            }
            Button("Reset", role: .destructive) {
                appStateManager.resetApp()
            }
        } message: {
            Text("This will reset all settings to default\(authenticationManager.userLoggedIn ? " and log you out of your account" : String()). This can't be undone!")
        }
#if os(macOS)
        .dialogSeverity(.critical)
#endif
        // Authentication form
        .sheet(item: $authenticationManager.formType) {_ in
            AuthenticationFormView()
                .environmentObject(appStateManager)
                .environmentObject(networkConnectionManager)
                .environmentObject(authenticationManager)
                .environmentObject(errorManager)
        }
    }
    
}

#Preview {
    AdvancedSettingsPageView()
        .withPreviewData()
}
