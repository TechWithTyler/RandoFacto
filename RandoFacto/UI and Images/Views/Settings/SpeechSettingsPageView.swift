//
//  SpeechSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI
import SheftAppsStylishUI

struct SpeechSettingsPageView: View {

    // MARK: - Properties - Speech Manager

    @EnvironmentObject var speechManager: SpeechManager

    // MARK: - Body

    var body: some View {
        Form {
            Section(footer: Text("This is the voice \(appName!) will use to read facts aloud.")) {
                VoicePicker(selectedVoiceID: $speechManager.selectedVoiceID, voices: speechManager.voices) { voice in
                    speechManager.speakFact(fact: sampleFact, forSettingsPreview: true)
                    }
                PlayButton(noun: "Sample Fact", isPlaying: speechManager.factBeingSpoken == sampleFact) {
                    if speechManager.factBeingSpoken == sampleFact {
                        speechManager.speechSynthesizer.stopSpeaking(at: .immediate)
                    } else {
                        speechManager.speakFact(fact: sampleFact, forSettingsPreview: true)
                    }
                }
            }
            .onAppear {
                speechManager.loadVoices()
            }
        }
        .formStyle(.grouped)
    }

}

// MARK: - Preview

#Preview {
    SpeechSettingsPageView()
        #if DEBUG
        .withPreviewData()
    #endif
}
