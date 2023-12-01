//
//  LoadingIndicator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/6/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct LoadingIndicator: View {

	var text: String?

    var body: some View {
		HStack {
			ProgressView()
				.progressViewStyle(.circular)
#if os(macOS)
				.controlSize(.small)
#endif
			if let text = text {
				Text(text)
					.padding(.horizontal)
			}
		}
    }
	
}

#Preview {
    LoadingIndicator()
}
