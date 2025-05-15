//
//  SettingsView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct SettingsView: View {

    // MARK: - Properties - Objects

    @EnvironmentObject var appStateManager: AppStateManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    // MARK: - Body

    var body: some View {
        if appStateManager.isLoading {
#if os(macOS)
            SAMVisualEffectViewSwiftUIRepresentable {
                loadingDisplay
                    .frame(width: 400, height: 280)
            }
#else
            loadingDisplay
#endif
        } else {
#if os(macOS)
            // macOS settings window
            TabView(selection: $appStateManager.selectedSettingsPage) {
                SAMVisualEffectViewSwiftUIRepresentable {
                    DisplaySettingsPageView()
                }
                .frame(width: 400, height: authenticationManager.userLoggedIn ? 450 : 280)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.display.rawValue.capitalized, systemImage: SettingsPage.Icons.display.rawValue)
                }
                .tag(SettingsPage.display)
                SAMVisualEffectViewSwiftUIRepresentable {
                    SpeechSettingsPageView()
                }
                .frame(width: 400, height: 150)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.speech.rawValue.capitalized, systemImage: SettingsPage.Icons.speech.rawValue)
                }
                .tag(SettingsPage.speech)
                SAMVisualEffectViewSwiftUIRepresentable {
                    AccountSettingsPageView()
                }
                .frame(width: 400, height: 270)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.account.rawValue.capitalized, systemImage: SettingsPage.Icons.account.rawValue)
                }
                .tag(SettingsPage.account)
                SAMVisualEffectViewSwiftUIRepresentable {
                    AdvancedSettingsPageView()
                }
                .frame(width: 400, height: 240)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.advanced.rawValue.capitalized, systemImage: SettingsPage.Icons.advanced.rawValue)
                }
                .tag(SettingsPage.advanced)
#if(DEBUG)
                SAMVisualEffectViewSwiftUIRepresentable {
                    DeveloperSettingsPageView()
                }
                .frame(width: 400, height: 535)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.developer.rawValue.capitalized, systemImage: SettingsPage.Icons.developer.rawValue)
                }
                .tag(SettingsPage.developer)
#endif
            }
#else
            // iOS/visionOS settings page
            NavigationStack {
                Form {
                    Section {
                        NavigationLink {
                            DisplaySettingsPageView()
                                .navigationTitle(SettingsPage.display.rawValue.capitalized)
                        } label: {
                            Label(SettingsPage.display.rawValue.capitalized, systemImage: SettingsPage.Icons.display.rawValue)
                        }
                        NavigationLink {
                            SpeechSettingsPageView()
                                .navigationTitle(SettingsPage.speech.rawValue.capitalized)
                        } label: {
                            Label(SettingsPage.speech.rawValue.capitalized, systemImage: SettingsPage.Icons.speech.rawValue)
                        }
                        NavigationLink {
                            AccountSettingsPageView()
                                .navigationTitle(SettingsPage.account.rawValue.capitalized)
                        } label: {
                            Label(SettingsPage.account.rawValue.capitalized, systemImage: SettingsPage.Icons.account.rawValue)
                        }
                        NavigationLink {
                            AdvancedSettingsPageView()
                                .navigationTitle(SettingsPage.advanced.rawValue.capitalized)
                        } label: {
                            Label(SettingsPage.advanced.rawValue.capitalized, systemImage: SettingsPage.Icons.advanced.rawValue)
                        }
                    }
#if(DEBUG)
                    NavigationLink {
                        DeveloperSettingsPageView()
                            .navigationTitle(SettingsPage.developer.rawValue.capitalized)
                    } label: {
                        Label(SettingsPage.developer.rawValue.capitalized, systemImage: SettingsPage.Icons.developer.rawValue)
                    }
#endif
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.automatic)
            .formStyle(.grouped)
#endif
        }
    }

    // MARK: - Loading Display

    var loadingDisplay: some View {
        Form {
            LoadingIndicator(message: pleaseWaitString)
                .padding()
        }
    }

}

#Preview("Loaded") {
    NavigationStack {
        SettingsView()
    }
#if DEBUG
.withPreviewData()
#endif
}

#Preview("Loading") {
    NavigationStack {
        SettingsView().loadingDisplay
    }
}
