//
//  InvalidCredentialsImage.swift
//  RandoFacto
//
//  Created by Tyler Sheft on 12/1/23.
//

import SwiftUI

struct InvalidCredentialsImage: View {
    var body: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .symbolRenderingMode(.multicolor)
    }
}

#Preview {
    InvalidCredentialsImage()
}
