//
//  SpeakButton.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/19/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct SpeakButton: View {
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    let fact: String
    
    init(for fact: String) {
        self.fact = fact
    }
    
    var body: some View {
        Button {
            appStateManager.speakFact(fact: fact)
        } label: {
            Label(appStateManager.factBeingSpoken == fact ? "Stop" : "Speak", systemImage: appStateManager.factBeingSpoken == fact ? "stop" : "speaker.wave.2.bubble.left.fill")
                .animatedSymbolReplacement()
        }
    }
}

#Preview {
    SpeakButton(for: "This is a test")
        .environmentObject(AppStateManager())
}
