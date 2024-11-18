//
//  FieldNeedsAttentionView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/1/23.
//  Copyright © 2022-2025 SheftApps. All rights reserved.
//

import SwiftUI

struct FieldNeedsAttentionView: View {
    
    var body: some View {
        VStack {
            if #available(macOS 14, iOS 17, visionOS 1, *) {
                fieldNeedsAttentionArrow
                // In 2023 OS versions and later, apply a pulsing color animation to the arrow.
                    .symbolEffect(.variableColor, options: .repeat(5).speed(5))
            } else {
                fieldNeedsAttentionArrow
            }
            Label("This field needs your attention.", systemImage: errorSymbolName)
                .symbolRenderingMode(.multicolor)
        }
            .foregroundStyle(.red)
    }
    
    @ViewBuilder var fieldNeedsAttentionArrow: some View {
        Image(systemName: "chevron.up")
            .accessibilityHidden(true)
    }
    
}

#Preview {
    FieldNeedsAttentionView()
}
