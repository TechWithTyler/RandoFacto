//
//  InvalidCredentialsImage.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/1/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct FieldNeedsAttentionButton: View {
    
    @State private var showingPopover: Bool = false
    
    var body: some View {
        Button {
            showingPopover.toggle()
        } label: {
            Image(systemName: errorSymbolName)
                .clipShape(.circle)
                .symbolRenderingMode(.multicolor)
                .accessibilityLabel(fieldNeedsAttentionString)
                .help(fieldNeedsAttentionString)
        }
        .popover(isPresented: $showingPopover) {
            Text(fieldNeedsAttentionString)
                .padding()
        }
        .buttonStyle(.borderless)
        #if os(iOS)
        .hoverEffect(.highlight)
        #endif
    }
}

#Preview {
    FieldNeedsAttentionButton()
}
