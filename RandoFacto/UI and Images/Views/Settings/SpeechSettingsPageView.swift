//
//  SpeechSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct SpeechSettingsPageView: View {

    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        Form {
            Section(footer: Text("This is the voice \(appName!) will use to read facts aloud.")) {
                VoicePicker(selectedVoiceID: $appStateManager.selectedVoiceID, voices: appStateManager.voices) { voice in
                    appStateManager.speakFact(fact: sampleFact, forSettingsPreview: true)
                    }
                PlayButton(noun: "Sample Fact", isPlaying: appStateManager.factBeingSpoken == sampleFact) {
                    if appStateManager.factBeingSpoken == sampleFact {
                        appStateManager.speechSynthesizer.stopSpeaking(at: .immediate)
                    } else {
                        appStateManager.speakFact(fact: sampleFact, forSettingsPreview: true)
                    }
                }
            }
            .onAppear {
                appStateManager.loadVoices()
            }
        }
        .formStyle(.grouped)
    }

}

#Preview {
    SpeechSettingsPageView()
        #if DEBUG
        .withPreviewData()
    #endif
}
