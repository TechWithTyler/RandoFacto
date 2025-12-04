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

    // MARK: - Properties - App State Manager

    @EnvironmentObject var windowStateManager: WindowStateManager

    // MARK: - Body

    var body: some View {
        Form {
            Section(footer: Text("This is the voice \(appName!) will use to read facts aloud.")) {
                VoicePicker(selectedVoiceID: $windowStateManager.selectedVoiceID, voices: windowStateManager.voices) { voice in
                    windowStateManager.speakFact(fact: sampleFact, forSettingsPreview: true)
                    }
                PlayButton(noun: "Sample Fact", isPlaying: windowStateManager.factBeingSpoken == sampleFact) {
                    if windowStateManager.factBeingSpoken == sampleFact {
                        windowStateManager.speechSynthesizer.stopSpeaking(at: .immediate)
                    } else {
                        windowStateManager.speakFact(fact: sampleFact, forSettingsPreview: true)
                    }
                }
            }
            .onAppear {
                windowStateManager.loadVoices()
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
