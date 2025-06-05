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
                fieldNeedsAttentionArrow
                // Apply a pulsing color animation to the arrow.
                    .symbolEffect(.variableColor, options: .repeat(5).speed(5))
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
