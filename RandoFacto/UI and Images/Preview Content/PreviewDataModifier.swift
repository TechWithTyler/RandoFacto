//
//  PreviewDataModifier.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/1/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct PreviewDataModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .environmentObject(PreviewManager.shared.appStateManager)
            .environmentObject(PreviewManager.shared.errorManager)
            .environmentObject(PreviewManager.shared.networkConnectionManager)
            .environmentObject(PreviewManager.shared.favoriteFactsDatabase)
            .environmentObject(PreviewManager.shared.authenticationManager)
            .environmentObject(PreviewManager.shared.favoriteFactsListDisplayManager)
    }

}

extension View {

    // Injects the app's model objects into Xcode Previews.
    func withPreviewData() -> some View {
        modifier(PreviewDataModifier())
    }

}
