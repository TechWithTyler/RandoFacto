//
//  SpeechSettingsPageView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/25/24.
//  Copyright © 2024 SheftApps. All rights reserved.
//

import SwiftUI
import SheftAppsStylishUI

struct SpeechSettingsPageView: View {

    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        Form {
            Section {
                VoicePicker(selectedVoiceID: $appStateManager.selectedVoiceID, voices: appStateManager.voices)
                    .onChange(of: appStateManager.selectedVoiceID) { value in
                        appStateManager.speakFact(fact: sampleFact)
                    }
            }
            .onAppear {
                appStateManager.loadVoices()
            }
        }
    }

}

#Preview {
    SpeechSettingsPageView()
        .withPreviewData()
}
