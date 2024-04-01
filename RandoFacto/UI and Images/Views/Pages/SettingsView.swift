//
//  SettingsView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/7/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct SettingsView: View {
    
    // MARK: - Properties - Objects
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager
    
    @EnvironmentObject var authenticationManager: AuthenticationManager
    
    @EnvironmentObject var errorManager: ErrorManager
    
    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase
    
    // MARK: - Properties - Fact Text Size Slider Text
    
    var factTextSizeSliderText: String {
        return "Fact Text Size: \(appStateManager.factTextSizeAsInt)"
    }
    
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
                    displayPage
                }
                .frame(width: 400, height: authenticationManager.userLoggedIn ? 420 : 280)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.display.rawValue.capitalized, systemImage: "textformat.size")
                }
                .tag(SettingsPage.display)
                SAMVisualEffectViewSwiftUIRepresentable {
                    accountPage
                }
                .frame(width: 400, height: 260)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.account.rawValue.capitalized, systemImage: "person.circle")
                }
                .tag(SettingsPage.account)
                SAMVisualEffectViewSwiftUIRepresentable {
                    advancedPage
                }
                .frame(width: 400, height: 150)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.advanced.rawValue.capitalized, systemImage: "gear")
                }
                .tag(SettingsPage.advanced)
#if(DEBUG)
                SAMVisualEffectViewSwiftUIRepresentable {
                    developerPage
                }
                .frame(width: 400, height: 500)
                .formStyle(.grouped)
                .tabItem {
                    Label(SettingsPage.developer.rawValue.capitalized, systemImage: "hammer")
                }
                .tag(SettingsPage.developer)
#endif
            }
#else
            // iOS/visionOS settings page
            NavigationStack {
                Form {
                    Section {
                        NavigationLink(SettingsPage.display.rawValue.capitalized) {
                            displayPage
                                .navigationTitle(SettingsPage.display.rawValue.capitalized)
                        }
                        NavigationLink(SettingsPage.account.rawValue.capitalized) {
                            accountPage
                                .navigationTitle(SettingsPage.account.rawValue.capitalized)
                        }
                        NavigationLink(SettingsPage.advanced.rawValue.capitalized) {
                            advancedPage
                                .navigationTitle(SettingsPage.advanced.rawValue.capitalized)
                        }
                    }
#if(DEBUG)
                    NavigationLink(SettingsPage.developer.rawValue.capitalized) {
                        developerPage
                            .navigationTitle(SettingsPage.developer.rawValue.capitalized)
                    }
#endif
                    Section {
                        Button("Help…") {
                            showHelp()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.automatic)
            .formStyle(.grouped)
#endif
        }
    }
    
    // MARK: - Display Page

    var displayPage: some View {
        Form {
            if authenticationManager.userLoggedIn {
                Section {
                    Picker("Fact on Launch", selection: $favoriteFactsDatabase.initialFact) {
                        Text(randomFactSettingTitle).tag(0)
                        Text("Random Favorite Fact").tag(1)
                    }
                } footer: {
                    Text("This setting will reset to \"\(randomFactSettingTitle)\" when you logout or delete your account.")
                }
                Section {
                    Toggle("Favorite Fact Randomizer Effect", isOn: $favoriteFactsDatabase.favoriteFactsRandomizerEffect)
                } footer: {
                    Text("This setting specifies whether a randomizer effect should be used when getting a random favorite fact instead of simply displaying a random favorite fact.")
                }
            }
            Section {
#if os(macOS)
                factTextSizeSlider
#else
                HStack {
                    Text(factTextSizeSliderText)
                    Spacer(minLength: 20)
                    factTextSizeSlider
                }
#endif
            }
            Section {
                Text(sampleFact)
                    .font(.system(size: CGFloat(appStateManager.factTextSize)))
            }
            .animation(.default, value: appStateManager.factTextSize)
            .formStyle(.grouped)
        }
    }
    
    // MARK: - Account Page
    
    var accountPage: some View {
        Form {
            Text((authenticationManager.firebaseAuthentication.currentUser?.email) ?? "Login to your RandoFacto account to save favorite facts to view on all your devices, even while offline.")
                .font(.system(size: 24))
                .fontWeight(.bold)
            if let deletionStage = authenticationManager.accountDeletionStage {
                LoadingIndicator(message: "Deleting \(deletionStage)…")
            } else if authenticationManager.userLoggedIn {
                if networkConnectionManager.deviceIsOnline {
                    Section {
                        Button("Change Password…") {
                            authenticationManager.formType = .passwordChange
                        }
                    }
                }
                Section {
                    Button("Logout…") {
                        authenticationManager.showingLogout = true
                    }
                }
                if networkConnectionManager.deviceIsOnline {
                    Section {
                        Button("DELETE ACCOUNT…", role: .destructive) {
                            authenticationManager.showingDeleteAccount = true
                        }
                    }
                }
            } else {
                if networkConnectionManager.deviceIsOnline {
                    Button(loginText) {
                        authenticationManager.formType = .login
                    }
                    Button(signupText) {
                        authenticationManager.formType = .signup
                    }
                } else {
                    Text("Authentication unavailable. Please check your internet connection.")
                        .font(.system(size: 24))
                }
            }
        }
        .formStyle(.grouped)
        // Delete account alert
        .alert("Are you sure you REALLY want to delete your RandoFacto account?", isPresented: $authenticationManager.showingDeleteAccount) {
            Button("Cancel", role: .cancel) {
                authenticationManager.showingDeleteAccount = false
            }
            Button("Delete", role: .destructive) {
                authenticationManager.deleteCurrentUser {
                    [self] error in
                    if let error = error {
                        DispatchQueue.main.async { [self] in
                            errorManager.showError(error) {
                                randoFactoError in
                                if randoFactoError == .tooLongSinceLastLogin {
                                    authenticationManager.formType = nil
                                    authenticationManager.logoutCurrentUser()
                                    errorManager.showingErrorAlert = true
                                } else {
                                    errorManager.showingErrorAlert = true
                                }
                            }
                        }
                    }
                    authenticationManager.showingDeleteAccount = false
                }
            }
        } message: {
            Text("You won't be able to save favorite facts to view offline! This can't be undone!")
        }
#if os(macOS)
        .dialogSeverity(.critical)
#endif
        // Logout alert
        .alert("Logout?", isPresented: $authenticationManager.showingLogout) {
            Button("Cancel", role: .cancel) {
                authenticationManager.showingLogout = false
            }
            Button("Logout") {
                authenticationManager.logoutCurrentUser()
                authenticationManager.showingLogout = false
            }
        } message: {
            Text("You won't be able to save favorite facts to view offline until you login again!")
        }
        // Authentication form
        .sheet(item: $authenticationManager.formType) {_ in
            AuthenticationFormView()
                .environmentObject(appStateManager)
                .environmentObject(networkConnectionManager)
                .environmentObject(authenticationManager)
                .environmentObject(errorManager)
        }
    }
    
    // MARK: - Advanced Page
    
    var advancedPage: some View {
        Form {
            Section {
                VoicePicker(selectedVoiceID: $appStateManager.selectedVoiceID, voices: appStateManager.voices)
                .onChange(of: appStateManager.selectedVoiceID) { value in
                    print("New voice ID: \(value)")
                    appStateManager.speakFact(fact: sampleFact)
                }
            }
            .onAppear {
                appStateManager.loadVoices()
            }
            Section {
                Button("RESET ALL SETTINGS…", role: .destructive) {
                    appStateManager.showingResetAlert = true
                }
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
    
    // MARK: - Loading Display
    
    var loadingDisplay: some View {
        Form {
            LoadingIndicator(message: pleaseWaitString)
                .padding()
        }
    }
    
    // MARK: - Fact Text Size Slider
    
    var factTextSizeSlider: some View {
        Slider(value: $appStateManager.factTextSize, in: SATextViewFontSizeRange, step: 1) {
            Text(factTextSizeSliderText)
        } minimumValueLabel: {
            Image(systemName: "textformat.size.smaller")
                .accessibilityLabel("Smaller")
        } maximumValueLabel: {
            Image(systemName: "textformat.size.larger")
                .accessibilityLabel("Larger")
        }
        .accessibilityValue("\(appStateManager.factTextSizeAsInt)")
    }
    
}

#Preview {
        SettingsView()
            .withPreviewData()
    #if os(macOS)
            .frame(height: 500)
    #endif
}

extension SettingsView {
    
    // MARK: - Developer Page (Internal Builds Only)
    
#if(DEBUG)
    var developerPage: some View {
        Form {
            Text("This page is available in internal builds only.")
            Section {
                Button("Reset Onboarding") {
                    appStateManager.shouldOnboard = true
                }
            }
            Section(header: Text("Fact Generation"), footer: Text("If a URL request doesn't succeed before the selected number of seconds passes since it started, a \"request timed out\" error is thrown.")) {
                HStack {
                    Text("Fact Generator URL")
                    Spacer()
                    Link(appStateManager.factGenerator.factURLString, destination: URL(string: appStateManager.factGenerator.factURLString)!)
                }
                HStack {
                    Text("Inappropriate Words Checker URL")
                    Spacer()
                    Link(appStateManager.factGenerator.inappropriateWordsCheckerURLString, destination: URL(string: appStateManager.factGenerator.inappropriateWordsCheckerURLString)!)
                }
                Picker("Timeout Interval (in seconds)", selection: $appStateManager.factGenerator.urlRequestTimeoutInterval) {
                    Text("0.25").tag(0.25)
                    Text("2").tag(2.0)
                    Text("10 (shipping build)").tag(10.0)
                    Text("30").tag(30.0)
                    Text("60 (system default)").tag(60.0)
                    Text("120").tag(120.0)
                }
            }
            Section("Backend") {
                Link("Open \(appName!) Firebase Console…", destination: URL(string: "https://console.firebase.google.com/u/0/project/randofacto-2b730/overview")!)
            }
        }
    }
#endif
    
}
