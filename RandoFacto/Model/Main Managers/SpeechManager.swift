//
//  SpeechManager.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/12/25.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

import SwiftUI
import Speech
import SheftAppsStylishUI

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    // MARK: - Properties - Strings

    @AppStorage(UserDefaults.KeyNames.selectedVoiceID) var selectedVoiceID: String = SADefaultVoiceID

    @AppStorage(UserDefaults.KeyNames.speakOnFactDisplay) var speakOnFactDisplay: Bool = false

    @Published var factBeingSpoken: String = String()

    // MARK: - Properties - Speech

    @Published var voices: [AVSpeechSynthesisVoice] = []

    var speechSynthesizer = AVSpeechSynthesizer()

    // MARK: - Initialization

    override init() {
        super.init()
        loadVoices()
        speechSynthesizer.delegate = self
    }

    // MARK: - Load Voices

    // This method loads all installed voices into the manager.
    func loadVoices() {
            AVSpeechSynthesizer.requestPersonalVoiceAuthorization { [self] status in
                voices = AVSpeechSynthesisVoice.speechVoices().filter({$0.language == "en-US"})
                if voices.filter({$0.identifier == selectedVoiceID}).isEmpty {
                    // If the selected voice ID is not available, set it to the default voice ID.
                    selectedVoiceID = SADefaultVoiceID
                }
            }
    }

    // MARK: - Speak Fact

    // This method speaks fact using the selected voice, or if fact is the fact currently being spoken, stops speech.
    func speakFact(fact: String, forSettingsPreview: Bool = false) {
        DispatchQueue.main.async { [self] in
            // 1. Stop any in-progress speech.
            speechSynthesizer.stopSpeaking(at: .immediate)
            // 2. If the fact to be spoken is the fact currently being spoken, speech is stopped and we don't continue. The exception is the sample fact which is spoken when choosing a voice--the sample fact is spoken each time the voice is changed regardless of whether it's currently being spoken.
            if factBeingSpoken != fact || forSettingsPreview {
                // 3. If we get here, create an AVSpeechUtterance with the given String (in this case, the fact passed into this method).
                let utterance = AVSpeechUtterance(string: fact)
                // 4. Set the voice for the utterance.
                utterance.voice = AVSpeechSynthesisVoice(identifier: selectedVoiceID)
                // 5. Speak the utterance.
                speechSynthesizer.speak(utterance)
            }
        }
    }

    // MARK: - Speech Synthesizer Delegate

    // This method sets factBeingSpoken to utterance's speechString when speech starts.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        factBeingSpoken = utterance.speechString
    }

    // This method resets factBeingSpoken to an empty String once speech completes or stops.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        factBeingSpoken = String()
    }

}
