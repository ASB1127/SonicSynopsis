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
    @Environment(\.dismiss) var Submit
    @Binding var audioName: String
    @State var initialName: String
    var recorder:KAudioRecorder
    var m4audios:[URL] = []
    var index:Int
    // MARK: - Body
    var body: some View {
            Spacer(minLength: 20)
            VStack{
                HStack{
                    Text("\(initialName)\(audioName)")
                        .font(.title)
                        .fontWeight(.bold)
                        .onAppear {
                            
                          
                        }
                       
                }
                
                .padding(.horizontal)
                Spacer()
                Button("Submit") {
                    Submit()
                    var oldName = String(m4audios[index].lastPathComponent)
                    oldName = "\(oldName)"
                    let newName = "\(audioName).m4a"
                    recorder.changeRecordingFileName(oldName: oldName, newName: newName)
                    audioName=""
                }
                Spacer(minLength: 5)
                .onChange(of: audioName) { newName in
                    if !newName.isEmpty {
                       
//                        m4audios[index].lastPathComponent = "\(newName).m4a"
                       
            
                     
                        
                        initialName = ""
                    }
                    
                }
                .onDisappear{
                    audioName=""
                }
                
            
        }
     
    }
    
    }


