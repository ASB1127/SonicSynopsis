//
//  ManageRecordingsView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 4/16/24.
//

import SwiftUI
import GoogleGenerativeAI
import Foundation

class FileManagerHelper {
    
    // MARK: - Change File Name
    
    static func changeFileName(fileURL: URL, newName: String) {
        let fileManager = FileManager.default
        let directoryURL = fileURL.deletingLastPathComponent()
        let newFileURL = directoryURL.appendingPathComponent(newName)
        
        do {
            try fileManager.moveItem(at: fileURL, to: newFileURL)
            print("File name changed successfully.")
        } catch {
            print("Error renaming file:", error.localizedDescription)
        }
    }
    
    // MARK: - Get File URL
    
    static func getFileURL(forFilename filename: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs {
                if fileURL.lastPathComponent == filename {
                    return fileURL
                }
            }
        } catch {
            print("Error while fetching filenames: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    // MARK: - Save File Name
    
    static func saveFileName(transcript: textobj, newName: String, jsonFile: inout [textobj]) {
        guard let index = jsonFile.firstIndex(where: { $0.id == transcript.id }) else { return }
        jsonFile[index].name = newName
        
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(jsonFile[index])
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("\(newName)")
            try jsonData.write(to: fileURL)
        } catch {
            print("Error saving filename:", error.localizedDescription)
        }
    }
    
    // MARK: - Delete File
    
    static func deleteTextFile(fileName: String) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("File \(fileName) deleted successfully.")
        } catch {
            print("Error deleting file \(fileName):", error.localizedDescription)
        }
    }
}



struct ManageTranscriptionsView: View {
    @State private var transcript:textobj? = nil
   
    @State private var jsonFile: [textobj] = []
    @State var name:String = ""
    @State private var selectedIndex:Int?
//    @State private var transcriptStructs: [transcriptionObj] = []
    @State private var selectedTranscript: textobj? = nil
    @State var transcriptContent:String = ""
    
    
    var body: some View {
        VStack {
            List {
                ForEach(jsonFile.indices, id: \.self) { index in
                    HStack {
                        Text(jsonFile[index].name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = index
                        selectedTranscript = jsonFile[index]
                    }
                    
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedIndex = index
                           
                            FileManagerHelper.deleteTextFile(fileName:jsonFile[selectedIndex ?? -1].name )
                            loadFiles()
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        .tint(.red)
                        
                        Button(action: {
                            Task {
                                selectedIndex = index
                               
                                await Summarize(jsonFile[selectedIndex!].content)
                            }
                        }) {
                            Label("Summarize", systemImage: "square.and.pencil")
                        }
                        .tint(.indigo)
                    }
                }
            }
            .onAppear {
                // Load filenames and transcripts
              loadFiles()
            }
            .preferredColorScheme(.dark)
        }
        .sheet(item: $selectedTranscript) { selectedTranscript in
            
            NextView(
                transcriptName: $name,
                transcriptContent: $transcriptContent
            )
            if #available(iOS 16.0, *) {
                TextField("\(selectedTranscript.name)",text: $name)
                    .keyboardType(/*@START_MENU_TOKEN@*/.default/*@END_MENU_TOKEN@*/)
                    .presentationDetents([.medium,.large])
                    .onAppear {
                        
                        transcriptContent = selectedTranscript.content
                    }
                    .onSubmit{
                        let fileURL = FileManagerHelper.getFileURL(forFilename: jsonFile[selectedIndex ?? -1].name)
                        
                        print("newName: ",name)
                       
                        print("oldName: ",jsonFile[selectedIndex ?? -1].name)
                        print("jsonFiles: ",jsonFile)
                        let nameJson = "\(name).json"
//                        saveFileName(transcript: jsonFile[selectedIndex!], newName: name)
                     
                        FileManagerHelper.changeFileName(fileURL: fileURL!, newName: nameJson)
                        FileManagerHelper.saveFileName(transcript: jsonFile[selectedIndex!], newName: nameJson, jsonFile: &jsonFile)
//                        deleteFileName(fileURL: fileURL!, filename: oldName)
//                        jsonFile[selectedIndex ?? -1].name=name
                    
                        
                        
                        
                    }
                    
                   
            } else {
                TextField("Enter your name",text: $name)
                    .keyboardType(/*@START_MENU_TOKEN@*/.default/*@END_MENU_TOKEN@*/)
                    .onAppear {
                        
                        transcriptContent = selectedTranscript.content
                    }
                    .onSubmit{
                        let fileURL = FileManagerHelper.getFileURL(forFilename: jsonFile[selectedIndex ?? -1].name)
                        
                        print("fileURL: ",fileURL!)
                        print("name: ",jsonFile[selectedIndex ?? -1].name)
                        jsonFile[selectedIndex ?? -1].name=name
                        
                        FileManagerHelper.changeFileName(fileURL: fileURL!, newName: name)
                        
                    }
            }
            
                
        }
    }
    private func saveFileName(transcript: textobj, newName: String) {
        guard let index = jsonFile.firstIndex(where: { $0.id == transcript.id }) else { return }
        print("In saveFileName() oldName: ",jsonFile[index].name)
        jsonFile[index].name = newName
        print("In saveFileName() newName: ",jsonFile[index].name)
        // Save updated filename to file
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(jsonFile[index])
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("\(newName)")
            try jsonData.write(to: fileURL)
            
            // Update filename in list
            jsonFile[index].name = newName
        } catch {
            print("Error saving filename:", error.localizedDescription)
        }
    }
    
   


        
        // Function to load filenames and transcripts
    //need to fix this function for the loading of transcript files
        private func loadFiles() {
           
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                let jsonFileURLs = fileURLs.filter { $0.pathExtension == "json" }
                if !jsonFileURLs.isEmpty {
                    jsonFile = jsonFileURLs.compactMap { url in
                        guard let data = try? Data(contentsOf: url) else { return nil }
                        guard let transcript = try? JSONDecoder().decode(textobj.self, from: data) else { return nil }
                        return transcript
                    }
                    jsonFile = jsonFile.map { $0 }
                }
            } catch {
                print("Error while fetching filenames: \(error.localizedDescription)")
            }
        }
        
    
    }



private func Summarize(_ summarize:String) async{

let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)
let prompt = "Give me a simple summary in note taking format of the following " + summarize

do{
let response = try await model.generateContent(prompt)
if let text = response.text {
print(text)
}
}
catch{
print("Error",error)
}


}

enum APIKey {
// Fetch the API key from `GenerativeAI-Info.plist`
static var `default`: String {
guard let filePath = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist")
else {
fatalError("Couldn't find file 'GenerativeAI-Info.plist'.")
}
let plist = NSDictionary(contentsOfFile: filePath)
guard let value = plist?.object(forKey: "API_KEY") as? String else {
fatalError("Couldn't find key 'API_KEY' in 'GenerativeAI-Info.plist'.")
}
if value.starts(with: "_") {
fatalError(
"Follow the instructions at https://ai.google.dev/tutorials/setup to get an API key."
)
}

return value
}
}


struct NextView: View {
    
    // MARK: - Properties
    @Environment (\.dismiss) var dismiss
    @Binding var transcriptName: String
    @Binding var transcriptContent: String
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 30){
            Text("\(transcriptName)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(transcriptContent)")
                .font(.body)
                .fontWeight(.medium)
            
            Button("Dismiss") {
                dismiss()
               
                transcriptName=""
            }
            .onDisappear{
                transcriptName=""
            }
        }
    }
}







        
