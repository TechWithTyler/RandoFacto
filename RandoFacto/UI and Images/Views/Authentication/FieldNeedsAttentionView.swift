//
//  FieldNeedsAttentionView.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/1/23.
//  Copyright © 2022-2024 SheftApps. All rights reserved.
//

import SwiftUI

struct FieldNeedsAttentionView: View {
    
    @State private var showingPopover: Bool = false
    
    var body: some View {
        Label(fieldNeedsAttentionString, systemImage: errorSymbolName)
            .symbolRenderingMode(.multicolor)
            .foregroundStyle(.red)
            .accessibilityLabel(fieldNeedsAttentionString)
    }
}

#Preview {
    FieldNeedsAttentionView()
}
