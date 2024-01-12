//
//  FieldNeedsAttentionView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/1/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct FieldNeedsAttentionView: View {
    
    var body: some View {
        VStack {
            if #available(macOS 14, iOS 17, visionOS 1, *) {
                chevron
                    .symbolEffect(.variableColor, options: .repeat(5).speed(5))
            } else {
                chevron
            }
            Label("This field needs your attention.", systemImage: errorSymbolName)
                .symbolRenderingMode(.multicolor)
        }
            .foregroundStyle(.red)
    }
    
    @ViewBuilder var chevron: some View {
        Image(systemName: "chevron.up")
            .accessibilityHidden(false)
    }
    
}

#Preview {
    FieldNeedsAttentionView()
}
