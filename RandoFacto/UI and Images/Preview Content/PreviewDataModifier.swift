//
//  PreviewDataModifier.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 4/1/24.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct PreviewDataModifier: ViewModifier {

    let previewManager: PreviewManager

    init(factText: String, authenticationFormType: Authentication.FormType, prepBlock: ((AppStateManager, ErrorManager, NetworkConnectionManager, FavoriteFactsDatabase, AuthenticationManager, FavoriteFactsListDisplayManager) -> Void)? = nil) {
        self.previewManager = PreviewManager(factText: factText, authenticationFormType: authenticationFormType, prepBlock: prepBlock)
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

    // Injects the app's model objects into Xcode Previews.
    func withPreviewData(factText: String = sampleFact, authenticationFormType: Authentication.FormType = .login, prepBlock: ((AppStateManager, ErrorManager, NetworkConnectionManager, FavoriteFactsDatabase, AuthenticationManager, FavoriteFactsListDisplayManager) -> Void)? = nil) -> some View {
        modifier(PreviewDataModifier(factText: factText, authenticationFormType: authenticationFormType, prepBlock: prepBlock))
    }

}
