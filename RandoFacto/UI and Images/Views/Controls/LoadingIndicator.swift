//
//  LoadingIndicator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/6/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

// A loading indicator.
struct LoadingIndicator: View {
    
    // MARK: - Properties - Text

    // The text for the loading indicator to display, if desired.
	var message: String?
    
    // MARK: - Body

    var body: some View {
		HStack {
			ProgressView()
				.progressViewStyle(.circular)
#if os(macOS)
				.controlSize(.small)
#endif
			if let message = message {
				Text(message)
					.padding(.horizontal)
			}
		}
    }
	
}

#Preview {
    LoadingIndicator()
        .previewDisplayName("Loading Indicator Without Label")
}

#Preview {
    LoadingIndicator(message: loadingString)
        .previewDisplayName("Loading Indicator With Label")
}
