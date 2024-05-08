//
//  EditFileNamesView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 5/1/24.
//

import SwiftUI

struct EditFileNamesView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @Binding var audioName: String
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 30) {
            Text("\(audioName)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Button("Dismiss") {
                dismiss()
                audioName = "" // Clear the audioName when dismissing
            }
            .onDisappear {
                audioName = "" // Clear the audioName when the view disappears
            }
        }
    }
}

