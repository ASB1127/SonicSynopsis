//
//  ManageRecordingsView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 4/16/24.
//

import SwiftUI

struct ManageTranscriptionsView: View {
    @State private var filenames: [String] = []
    @State private var txtFileNames: [String] = []
    @State private var selectedIndex:Int = 0
    @State private var transcriptStructs: [transcriptionObj] = []
    @State private var showAlert = false
    var body: some View {
           VStack {
               List {
                   ForEach(txtFileNames.indices, id: \.self) { index in
                       HStack {
                           Group {
                               
                                   Text(txtFileNames[index])
                                   Spacer()
                               }
                           }
                       
                       
                       .contentShape(Rectangle())
                       .onTapGesture {
                           // Handle tap on the list element here
                           print("Tapped:", txtFileNames[index])
                       }
                   }
               }
               .onAppear {
                   // Get the documents directory URL
                   let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                   
                   do {
                       // Get the contents of the documents directory
                       let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                       let txtFileURLs = fileURLs.filter { $0.pathExtension == "json" }
                       if(txtFileURLs.count>0){
                           transcriptStructs = getTranscriptionStructArray(fileURLs: txtFileURLs)
                           print("name in manageTranscriptions",transcriptStructs[0].name)
                           
                           //                       for i in 0...fileURLs.count-1{
                           //                           getTranscriptionStruct(fileURL: fileURLs[i])
                           //                       }
                           // Extract filenames from the URLs and update the state
                           filenames = fileURLs.map { $0.lastPathComponent }
                           txtFileNames = filenames.filter { $0.hasSuffix("json") }
                       }
                       else{
                           
                           return
                       }
//                       print(txtFileNames)
                       
                   } catch {
                       // Handle error
                       print("Error while fetching filenames: \(error.localizedDescription)")
                   }
               }
               .preferredColorScheme(.dark)
           }
       }

   }

private func getTranscriptionStructArray(fileURLs:[URL])->Array<transcriptionObj>
{
    var transcriptionArray:[transcriptionObj] = []
    for i in fileURLs.indices {
        transcriptionArray.append(getTranscriptionStruct(fileURL: fileURLs[i]))
    }
    return transcriptionArray
}
private func getTranscriptionStruct(fileURL:URL)-> transcriptionObj{
    var transcriptFinal = transcriptionObj(name: "", content: "")
    if FileManager.default.fileExists(atPath: fileURL.path) {
                       do {
                           let data = try Data(contentsOf: fileURL)
                 
                           transcriptFinal = try JSONDecoder().decode(transcriptionObj.self, from: data)
                           print("transcriptFinal: \n",transcriptFinal.name+"\n"+transcriptFinal.content)
                           if let string = String(data: data, encoding: .utf8) {
                                  print("File contents: \(string)")
                              }
                           
                       } catch {
                           print("Error reading or decoding data:", error)
                       }
                   } else {
                       print("File does not exist at path:", fileURL.path)
                   }
                   do {
                       try transcription?.write(to: fileURL, atomically: true, encoding: .utf8)
                          // print("Transcription saved to:", fileURL)
                       } catch {
                           print("Error saving transcription:", error.localizedDescription)
                       }
    return transcriptFinal
    
}
        
        #Preview {
            ManageTranscriptionsView()
        }
        
