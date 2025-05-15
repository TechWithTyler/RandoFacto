//
//  SpeakButton.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/19/24.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI

struct SpeakButton: View {
    
    @EnvironmentObject var appStateManager: AppStateManager
    
    let fact: String

    let useShortTitle: Bool

    init(for fact: String, useShortTitle: Bool = true) {
        self.fact = fact
        self.useShortTitle = useShortTitle
    }
    
    var body: some View {
        Button {
            appStateManager.speakFact(fact: fact)
        } label: {
            Label(appStateManager.factBeingSpoken == fact ? (useShortTitle ? "Stop" : "Stop Speaking") : (useShortTitle ? "Speak" : "Speak Fact"), systemImage: appStateManager.factBeingSpoken == fact ? "stop" : speechSymbolName)
                .frame(width: 30)
                .animatedSymbolReplacement()
        }
    }
}

#Preview {
        SpeakButton(for: "This is a test")
            .labelStyle(.topIconBottomTitle)
#if DEBUG
            .withPreviewData()
#endif
}
