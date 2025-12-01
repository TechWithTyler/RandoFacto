//
//  SpeakButton.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 1/19/24.
//  Copyright © 2022-2026 SheftApps. All rights reserved.
//

// MARK: - Imports

import SwiftUI

struct SpeakButton: View {

    // MARK: - Properties - App State Manager

    @EnvironmentObject var appStateManager: AppStateManager

    // MARK: - Properties - Strings

    let fact: String

    // MARK: - Properties - Booleans

    let useShortTitle: Bool

    // MARK: - Initialization

    init(for fact: String, useShortTitle: Bool = true) {
        self.fact = fact
        self.useShortTitle = useShortTitle
    }

    // MARK: - Body

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

// MARK: - Preview

#Preview {
        SpeakButton(for: "This is a test")
            .labelStyle(.topIconBottomTitle)
#if DEBUG
            .withPreviewData()
#endif
}
