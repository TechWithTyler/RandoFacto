//
//  SettingsView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

struct SettingsView: View {

    // MARK: - Properties - Objects

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var errorManager: ErrorManager

    // MARK: - Properties - Selected Settings Page

#if os(macOS)
    // The page currently selected in the Settings window on macOS.
    @AppStorage(UserDefaults.KeyNames.selectedSettingsPage) var selectedSettingsPage: SettingsPage = .facts
#endif

    // MARK: - Body

    var body: some View {
#if os(macOS)
            // macOS settings window
            TabView(selection: $selectedSettingsPage) {
                SAMVisualEffectViewSwiftUIRepresentable(activeState: .active) {
                    FactSettingsPageView()
                }
                .frame(width: 400, height: authenticationManager.userLoggedIn ? 450 : 280)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.facts.title, systemImage: SettingsPage.Icons.facts.rawValue)
                }
                .tag(SettingsPage.facts)
                SAMVisualEffectViewSwiftUIRepresentable(activeState: .active) {
                    SpeechSettingsPageView()
                }
                .frame(width: 400, height: 200)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.speech.title, systemImage: SettingsPage.Icons.speech.rawValue)
                }
                .tag(SettingsPage.speech)
                SAMVisualEffectViewSwiftUIRepresentable(activeState: .active) {
                    AccountSettingsPageView()
                }
                .frame(width: 400, height: 270)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.account.title, systemImage: SettingsPage.Icons.account.rawValue)
                }
                .tag(SettingsPage.account)
                SAMVisualEffectViewSwiftUIRepresentable(activeState: .active) {
                    AdvancedSettingsPageView()
                }
                .frame(width: 400, height: 240)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.advanced.title, systemImage: SettingsPage.Icons.advanced.rawValue)
                }
                .tag(SettingsPage.advanced)
#if(DEBUG)
                SAMVisualEffectViewSwiftUIRepresentable(activeState: .active) {
                    DeveloperSettingsPageView()
                }
                .frame(width: 400, height: 535)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.developer.title, systemImage: SettingsPage.Icons.developer.rawValue)
                }
                .tag(SettingsPage.developer)
#endif
            }
            // Error alert
            .alert(isPresented: $errorManager.showingErrorAlert, error: errorManager.errorToShow) {
                Button {
                    errorManager.errorToShow = nil
                } label: {
                    Text("OK")
                }
            }
            .dialogSeverity(.critical)
            // Error sound
            .onChange(of: errorManager.errorToShow) { oldError, newError in
                if newError != nil {
                    NSSound.beep()
                }
            }
#else
            // iOS/visionOS settings page
            NavigationStack {
                Form {
                    Section {
                        NavigationLink {
                            FactSettingsPageView()
                                .navigationTitle(SettingsPage.facts.title)
                        } label: {
                            Label(SettingsPage.facts.title, systemImage: SettingsPage.Icons.facts.rawValue)
                        }
                        NavigationLink {
                            SpeechSettingsPageView()
                                .navigationTitle(SettingsPage.speech.title)
                        } label: {
                            Label(SettingsPage.speech.title, systemImage: SettingsPage.Icons.speech.rawValue)
                        }
                        NavigationLink {
                            AccountSettingsPageView()
                                .navigationTitle(SettingsPage.account.title)
                        } label: {
                            Label(SettingsPage.account.title, systemImage: SettingsPage.Icons.account.rawValue)
                        }
                        NavigationLink {
                            AdvancedSettingsPageView()
                                .navigationTitle(SettingsPage.advanced.title)
                        } label: {
                            Label(SettingsPage.advanced.title, systemImage: SettingsPage.Icons.advanced.rawValue)
                        }
                    }
#if(DEBUG)
                    NavigationLink {
                        DeveloperSettingsPageView()
                            .navigationTitle(SettingsPage.developer.title)
                    } label: {
                        Label(SettingsPage.developer.title, systemImage: SettingsPage.Icons.developer.rawValue)
                    }
#endif
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.automatic)
            .formStyle(.grouped)
#endif
    }

    // MARK: - Loading Display

    var loadingDisplay: some View {
        Form {
            LoadingIndicator(message: pleaseWaitString)
                .padding()
        }
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
    }
#if DEBUG
    .withPreviewData()
#endif
}
