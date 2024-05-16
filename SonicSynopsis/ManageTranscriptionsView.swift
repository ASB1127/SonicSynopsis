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
    

    
    static func saveFileName(transcript: textobj, newName: String, jsonFile: inout [textobj]) {
        guard let index = jsonFile.firstIndex(where: { $0.id == transcript.id }) else { return }
        jsonFile[index].name = newName
        print("saveFileName() newName: ", newName)
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
    
    @State private var transcriptFile: [textobj] = []
    @State var name:String = ""
    @State private var selectedIndex:Int?
    //    @State private var transcriptStructs: [transcriptionObj] = []
    @State private var selectedTranscript: textobj? = nil
    @State var transcriptContent:String = ""
    @State private var summary: textobj? = nil
    @Binding var shouldRedrawTranscriptionView: Bool
    @Binding var shouldRedrawSummaryView:Bool
  
    
    var body: some View {
       
        VStack {
            
            List {
                ForEach(transcriptFile.indices, id: \.self) { index in
                    
                    HStack {
                        Text(transcriptFile[index].name)
                        Spacer(minLength: 2)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = index
                        selectedTranscript = transcriptFile[index]
                    }
                    
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedIndex = index
                            
                            FileManagerHelper.deleteTextFile(fileName:transcriptFile[selectedIndex ?? -1].name )
                            loadFiles(pathExtension: "transcription")
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        .tint(.red)
                        
                        Button(action: {
                            
                            Task {
                                selectedIndex = index
                                let summary = await Summarize(transcriptFile[selectedIndex!].content)
                                
                                print("Summary:", summary)
                                
                                let recentFileName = getMostRecentSummaryFileName()
                                print("recentFileName: ", recentFileName)
                                saveSummaryToFile(summary: summary, fileName: recentFileName)
                                shouldRedrawSummaryView = true
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
                loadFiles(pathExtension: "transcription")
                
            }
            .onChange(of: shouldRedrawTranscriptionView) { newValue in
                            if newValue {
                                loadFiles(pathExtension: "transcription")
                                shouldRedrawTranscriptionView = false
                            }
                        }
            .preferredColorScheme(.dark)
        }
        .sheet(item: $selectedTranscript) { selectedTranscript in
           
            EditTranscriptionsView(
                transcriptName: $name,
                transcriptContent: $transcriptContent,
                
                initialName: selectedTranscript.name,
                transcriptFile:transcriptFile,
                fileManagerHelper: FileManagerHelper.init(),
                transcript: selectedTranscript
                
            )
            .onDisappear {
                   // Perform actions when the sheet is dismissed
                   loadFiles(pathExtension: "transcription")
               }
            
            if #available(iOS 16.0, *) {
                HStack {
                    Spacer(minLength: 20)
                    TextField("\(selectedTranscript.name)",text: $name)
                        .keyboardType(/*@START_MENU_TOKEN@*/.default/*@END_MENU_TOKEN@*/)
                        .presentationDetents([.medium,.large])
                        .onAppear {
                            
                            transcriptContent = selectedTranscript.content
                        }
                        .onSubmit{
                            let fileURL = FileManagerHelper.getFileURL(forFilename: transcriptFile[selectedIndex ?? -1].name)
                            
                            print("newName: ",name)
                            
                            print("oldName: ",transcriptFile[selectedIndex ?? -1].name)
                            print("jsonFiles: ",transcriptFile)
                            let nameTranscript = "\(name).transcription"
                            //                        saveFileName(transcript: jsonFile[selectedIndex!], newName: name)
                            
                            FileManagerHelper.changeFileName(fileURL: fileURL!, newName: nameTranscript)
                            FileManagerHelper.saveFileName(transcript: transcriptFile[selectedIndex!], newName: nameTranscript, jsonFile: &transcriptFile)
                            //                        deleteFileName(fileURL: fileURL!, filename: oldName)
                            //                        jsonFile[selectedIndex ?? -1].name=name
                            
                            
                            
                            
                        }
                }
                
                
            } else {
                HStack {
                    Spacer(minLength: 20)
                    TextField("\(selectedTranscript.name)",text: $name)
                        .keyboardType(/*@START_MENU_TOKEN@*/.default/*@END_MENU_TOKEN@*/)
                        .onAppear {
                            
                            transcriptContent = selectedTranscript.content
                        }
                        .onSubmit{
                            let fileURL = FileManagerHelper.getFileURL(forFilename: transcriptFile[selectedIndex ?? -1].name)
                            
                            print("fileURL: ",fileURL!)
                            print("name: ",transcriptFile[selectedIndex ?? -1].name)
                            transcriptFile[selectedIndex ?? -1].name=name
                            
                            FileManagerHelper.changeFileName(fileURL: fileURL!, newName: name)
                            
                        }
                }
            }
            
            
        }
    }
    
    
    
    // Function to load filenames and transcripts
    //need to fix this function for the loading of transcript files
    private func loadFiles(pathExtension:String) {
        print("loadFiles: pathExtension",pathExtension)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            let jsonFileURLs = fileURLs.filter { $0.pathExtension == pathExtension }
            if !jsonFileURLs.isEmpty {
                transcriptFile = jsonFileURLs.compactMap { url in
                    guard let data = try? Data(contentsOf: url) else { return nil }
                    guard let transcript = try? JSONDecoder().decode(textobj.self, from: data) else { return nil }
                    return transcript
                }
                
                print("transcriptFile[len-1]",transcriptFile[transcriptFile.count-1].name)
                print("transcriptFIle[len-2]")
//                if(transcriptFile[transcriptFile.count-1].name != transcriptFile[transcriptFile.count-2].name)
//                {
                    transcriptFile = transcriptFile.map { $0 }
//                }
                transcriptFile = transcriptFile.sorted()
            }
        } catch {
            print("Error while fetching filenames: \(error.localizedDescription)")
        }
    }
    
    
}



private func Summarize(_ summarize:String) async -> String{
    
    let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)
    let prompt = "Give me a simple summary in note taking format of the following " + summarize
    
    do{
        let response = try await model.generateContent(prompt)
        if let text = response.text {
            return text
        }
    }
    catch{
        print("Error",error)
    }
    
    return "Empty"
}

private func saveSummaryToFile(summary: String, fileName:String){
    print("fileName: ",fileName)
    var data = Data()
    let summary = textobj.init(name: fileName, content: summary)
    
    do{
        
        data = try JSONEncoder().encode(summary)
        
        
    }
    catch{
        
        print("Error encoding transcript: \(error)")
    }
    
    
    
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    //    print("documentsdir: \n",documentsDirectory)
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    print("fileURL: ", fileURL)
    do{
        try data.write(to: fileURL)
        print("Data saved successfully to \(fileURL)")
    }
    catch{
        print("Error saving data: \(error)")
    }
    
}

private func getMostRecentSummaryFileName() -> String {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    var mostRecentFileURL: URL?
   
    var maxCount = -1
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
       
        for fileURL in fileURLs {
            let fileName = fileURL.lastPathComponent
      
       
            let pattern = "summary([0-9]+).summary"
            
            let nameRange = NSRange(
                fileName.startIndex..<fileName.endIndex,
                in: fileName
            )
            let regex = try! NSRegularExpression(
                pattern: pattern,
                options: []
            )
            
            let matches = regex.matches(
                in: fileName,
                options: [],
                range: nameRange
            )
            
            guard let match = matches.first else {
                // Handle exception
                continue
            }
            
            for rangeIndex in 0..<match.numberOfRanges {
                let matchRange = match.range(at: rangeIndex)
                
                // Ignore matching the entire username string
                if matchRange == nameRange { continue }
                
                // Extract the substring matching the capture group
                if let substringRange = Range(matchRange, in: fileName) {
                    let count = String(fileName[substringRange])
                    print("getMostRecentSummaryFileName() count=",count, "maxCount=",maxCount)
                    if Int(count)! > maxCount {
                        print("maxcount setting to count count=",count)
                        maxCount = Int(count)!
                    }
                }
            }
        }
        
        // If no valid filenames found, set most recent filename to have count 0
      
    } catch {
        print("Error while enumerating files:", error)
    }
    
    if maxCount == -1 {
        print("No valid filenames found")
        let defaultFileName = "summary1.summary"
        mostRecentFileURL = documentsURL.appendingPathComponent(defaultFileName)
    }else{
        maxCount+=1
        print("getMostRecentSummaryFileName() maxCount:",maxCount)
        let defaultFileName = "summary\(maxCount).summary"
        mostRecentFileURL = documentsURL.appendingPathComponent(defaultFileName)
    }
    
    return mostRecentFileURL!.lastPathComponent
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


struct EditTranscriptionsView: View {
    
    // MARK: - Properties
    @Environment (\.dismiss) var submit
    @Binding var transcriptName: String
    @Binding var transcriptContent: String
    @State var initialName:String
    @State var transcriptFile:[textobj] = []
    var fileManagerHelper:FileManagerHelper
    var transcript:textobj
    // MARK: - Body
    var body: some View {
        Spacer(minLength: 30)
        VStack{
            HStack{
                Text("\(initialName)\(transcriptName)")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            Spacer(minLength: 40)
            ScrollView {
                Text("\(transcriptContent)")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .onChange(of: transcriptName) { newName in
                if !newName.isEmpty {
                    initialName = ""
                }
            }
            
            Button("Submit") {
                submit()
                
                let fileURL = FileManagerHelper.getFileURL(forFilename: transcript.name)
                let nameTranscript = "\(transcriptName).transcription"
                //                        saveFileName(transcript: jsonFile[selectedIndex!], newName: name)
                print("transcript: ",transcriptName)
                FileManagerHelper.changeFileName(fileURL: fileURL!, newName: nameTranscript)
                FileManagerHelper.saveFileName(transcript: transcript, newName: nameTranscript, jsonFile: &transcriptFile)
                transcriptName=""
           
            }
            .onDisappear{
                transcriptName=""
           
            }
        }
    }
}







        
