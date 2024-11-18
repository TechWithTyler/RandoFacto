//
//  PreviewDataModifier.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/1/24.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI

struct PreviewDataModifier: ViewModifier {

    let previewManager: PreviewManager

    init(prepBlock: ((AppStateManager, ErrorManager, NetworkConnectionManager, FavoriteFactsDatabase, AuthenticationManager, FavoriteFactsListDisplayManager) -> Void)? = nil) {
        self.previewManager = PreviewManager(prepBlock: prepBlock)
    }

    func body(content: Content) -> some View {
        content
            .environmentObject(previewManager.appStateManager)
            .environmentObject(previewManager.errorManager)
            .environmentObject(previewManager.networkConnectionManager)
            .environmentObject(previewManager.favoriteFactsDatabase)
            .environmentObject(previewManager.authenticationManager)
            .environmentObject(previewManager.favoriteFactsListDisplayManager)
    }

}

extension View {

    // Injects the app's model objects into Xcode Previews and allows access to them.
    func withPreviewData(prepBlock: ((AppStateManager, ErrorManager, NetworkConnectionManager, FavoriteFactsDatabase, AuthenticationManager, FavoriteFactsListDisplayManager) -> Void)? = nil) -> some View {
        modifier(PreviewDataModifier(prepBlock: prepBlock))
    }

}
