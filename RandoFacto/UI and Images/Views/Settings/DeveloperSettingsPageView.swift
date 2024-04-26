//
//  DeveloperSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

#if(DEBUG)
import SwiftUI

struct DeveloperSettingsPageView: View {

    @EnvironmentObject var appStateManager: AppStateManager

    @EnvironmentObject var networkConnectionManager: NetworkConnectionManager

    @EnvironmentObject var authenticationManager: AuthenticationManager

    @EnvironmentObject var errorManager: ErrorManager

    @EnvironmentObject var favoriteFactsDatabase: FavoriteFactsDatabase

    // MARK: - Developer Settings Page (Internal Builds Only)

    var body: some View {
        // Put any internal/development-related features/settings here to hide them from release builds.
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
            Section("Firebase/Backend") {
                Link("Open \(appName!) Firebase Console…", destination: URL(string: "https://console.firebase.google.com/u/0/project/randofacto-2b730/overview")!)
                Button("Crash Test!", systemImage: "exclamationmark.triangle") {
#if os(macOS)
                    NSSound.beep()
                    Thread.sleep(forTimeInterval: 1)
#endif
                    fatalError("This is a test of \(appName!)'s Firebase Crashlytics mechanism on \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .full)). The button that triggered this crash won't be seen in release builds. Build and run the app via Xcode to upload this crash to Crashlytics.")
                }
            }
        }
    }

}

#Preview {
    DeveloperSettingsPageView()
        .withPreviewData()
}
#endif
