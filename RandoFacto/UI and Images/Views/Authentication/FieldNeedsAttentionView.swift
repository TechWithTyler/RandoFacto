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
        Label("This field needs your attention.", systemImage: errorSymbolName)
            .symbolRenderingMode(.multicolor)
            .foregroundStyle(.red)
    }
    
}

#Preview {
    FieldNeedsAttentionView()
}
