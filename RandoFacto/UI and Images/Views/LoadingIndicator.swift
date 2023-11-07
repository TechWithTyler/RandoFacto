//
//  LoadingIndicator.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 11/6/23.
//  Copyright © 2022-2023 SheftApps. All rights reserved.
//

import SwiftUI

struct LoadingIndicator: View {

    var body: some View {
		ProgressView()
			.progressViewStyle(.circular)
#if os(macOS)
			.controlSize(.small)
#endif
    }
	
}

#Preview {
    LoadingIndicator()
}
