//
//  EditFileNamesView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 5/1/24.
//

import SwiftUI
import AVFAudio

struct EditFileNamesView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @Binding var audioName: String
    @State var initialName: String
    var recorder:KAudioRecorder
    // MARK: - Body
    var body: some View {
            Spacer(minLength: 20)
            VStack{
                HStack{
                    Text("\(initialName)\(audioName)")
                        .font(.title)
                        .fontWeight(.bold)
                       
                }
                .padding(.horizontal)
                Spacer()
                Button("Dismiss") {
                    dismiss()
                    
                    audioName=""
                }
                Spacer(minLength: 5)
                .onChange(of: audioName) { newName in
                    if !newName.isEmpty {
                        initialName = ""
                        recorder.changeRecordingFileName(oldName: initialName, newName: audioName)
                    }
                    
                }
                .onDisappear{
                    audioName=""
                }
                
            
        }
     
    }
    
    }


