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

//Class FolderMonitor Source From: https://medium.com/over-engineering/monitoring-a-folder-for-changes-in-ios-dc3f8614f902
class FolderMonitor {
    
    /// A file descriptor for the monitored directory.
    private var monitoredFolderFileDescriptor: CInt = -1
    /// A dispatch queue used for sending file changes in the directory.
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    /// A dispatch source to monitor a file descriptor created from the directory.
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    /// URL for the directory being monitored.
    let url: Foundation.URL
    
    var folderDidChange: (() -> Void)?
    // MARK: Initializers
    init(url: Foundation.URL) {
        self.url = url
    }
    // MARK: Monitoring
    /// Listen for changes to the directory (if we are not already).
    func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
            
        }
        // Open the directory referenced by URL for monitoring only.
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        // Define a dispatch source monitoring the directory for additions, deletions, and renamings.
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: [.all], queue: folderMonitorQueue)
        // Define the block to call when a file change is detected.
        folderMonitorSource?.setEventHandler { [weak self] in
            self?.folderDidChange?()
        }
        // Define a cancel handler to ensure the directory is closed when the source is cancelled.
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredFolderFileDescriptor)
            strongSelf.monitoredFolderFileDescriptor = -1
            strongSelf.folderMonitorSource = nil
        }
        // Start monitoring the directory via the source.
        folderMonitorSource?.resume()
    }
    /// Stop listening for changes to the directory, if the source has been created.
    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}

//Class Folder Source From: https://medium.com/over-engineering/monitoring-a-folder-for-changes-in-ios-dc3f8614f902
class Folder: ObservableObject {
    private let filter: String
    @Published  var transcriptFile: [textobj] = []
    @Published  var summaryFile: [textobj] = []
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
    private lazy var folderMonitor = FolderMonitor(url: self.url)
    
    init(filter: String) {
        self.filter = filter
        folderMonitor.folderDidChange = { [weak self] in
            self?.handleChanges()
        }
        folderMonitor.startMonitoring()
        self.handleChanges()
    }
    
    func handleChanges() {
        print("Folder: Observed Object - handleChanges")
        //let files = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)) ?? []
        DispatchQueue.main.async {
            self.transcriptFile =  self.loadFiles(pathExtension: self.filter)
        }
        
        
        
        
    }
    // Function to load filenames and transcripts
     func loadFiles(pathExtension:String)->[textobj] {
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
                
                print("textObj[len-1]",transcriptFile[transcriptFile.count-1].name)
                print("textObj[len-2]",transcriptFile[transcriptFile.count-1].name)
                //                if(transcriptFile[transcriptFile.count-1].name != transcriptFile[transcriptFile.count-2].name)
                //                {
                let transcriptFiletemp = transcriptFile.map { $0 }
                
                //                }
                transcriptFile = transcriptFiletemp.sorted()
                print("exited successfully")
                print("***transcriptFile=",transcriptFile[transcriptFile.count-1].content)
                return transcriptFile
            }
        } catch {
            print("Error while fetching filenames: \(error.localizedDescription)")
        }
        return transcriptFile
    }
}

extension URL: Identifiable {
    public var id: String { return lastPathComponent }
}


struct ManageTranscriptionsView: View {
    @ObservedObject var folder = Folder(filter: "transcription")
    
    @State var name:String = ""
    @State private var selectedIndex:Int?
    //    @State private var transcriptStructs: [transcriptionObj] = []
    @State private var selectedTranscript: textobj? = nil
    @State var transcriptContent:String = ""
    @State private var summary: textobj? = nil
    @Binding var shouldRedrawTranscriptionView: Bool
    @Binding var shouldRedrawSummaryView:Bool
    @State private var refreshView = false
    
    var body: some View {
        
        
        VStack {
            
            
            List {
                ForEach(folder.transcriptFile.indices, id: \.self) { index in
                    
                    HStack {
                        Text(folder.transcriptFile[index].name)
                        Spacer(minLength: 2)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = index
                        selectedTranscript = folder.transcriptFile[index]
                    }
                    
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedIndex = index
                            
                            FileManagerHelper.deleteTextFile(fileName:folder.transcriptFile[selectedIndex ?? -1].name )
                            //                            loadFiles(pathExtension: "transcription")
                            //                            shouldRedrawTranscriptionView = false
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        .tint(.red)
                        
                        Button(action: {
                            
                            Task {
                                selectedIndex = index
                                let summary = await Summarize(folder.transcriptFile[selectedIndex!].content)
                                
                                print("Summary:", summary)
                                
                                let recentFileName = getMostRecentSummaryFileName()
                                print("recentFileName: ", recentFileName)
                                saveSummaryToFile(summary: summary, fileName: recentFileName)
                                //                                shouldRedrawSummaryView = true
                            }
                            
                            
                        }) {
                            Label("Summarize", systemImage: "square.and.pencil")
                        }
                        .tint(.indigo)
                    }
                }
            }
            //            .onAppear {
            //                // Load filenames and transcripts
            ////                loadFiles(pathExtension: "transcription")
            //
            //            }
            //            .onChange(of: shouldRedrawTranscriptionView) { newValue in
            //                if newValue {
            //                    loadFiles(pathExtension: "transcription")
            //                    shouldRedrawTranscriptionView = false
            //                }
            //            }
            .preferredColorScheme(.dark)
            .id(refreshView)
        }
        .sheet(item: $selectedTranscript) { selectedTranscript in
            
            EditTranscriptionsView(
                transcriptName: $name,
                transcriptContent: $transcriptContent,
                
                initialName: selectedTranscript.name,
                transcriptFile:folder.transcriptFile,
                fileManagerHelper: FileManagerHelper.init(),
                transcript: selectedTranscript
                
            )
            .onDisappear {
                               // Perform actions when the sheet is dismissed
                var res = folder.loadFiles(pathExtension: "transcription")
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
                            let fileURL = FileManagerHelper.getFileURL(forFilename: folder.transcriptFile[selectedIndex ?? -1].name)
                            
                            print("newName: ",name)
                            
                            print("oldName: ",folder.transcriptFile[selectedIndex ?? -1].name)
                            print("jsonFiles: ",folder.transcriptFile)
                            let nameTranscript = "\(name).transcription"
                            //                        saveFileName(transcript: jsonFile[selectedIndex!], newName: name)
                            
                            FileManagerHelper.changeFileName(fileURL: fileURL!, newName: nameTranscript)
                            FileManagerHelper.saveFileName(transcript: folder.transcriptFile[selectedIndex!], newName: nameTranscript, jsonFile: &folder.transcriptFile)
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
                            let fileURL = FileManagerHelper.getFileURL(forFilename: folder.transcriptFile[selectedIndex ?? -1].name)
                            
                            print("fileURL: ",fileURL!)
                            print("name: ",folder.transcriptFile[selectedIndex ?? -1].name)
                            folder.transcriptFile[selectedIndex ?? -1].name=name
                            
                            FileManagerHelper.changeFileName(fileURL: fileURL!, newName: name)
                            
                        }
                }
            }
            
            
        }
    }
    
}
    
    // Function to load filenames and transcripts
    //    //need to fix this function for the loading of transcript files
    //    private func loadFiles(pathExtension:String) {
    //        print("loadFiles: pathExtension",pathExtension)
    //        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    //
    //        do {
    //            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
    //            let jsonFileURLs = fileURLs.filter { $0.pathExtension == pathExtension }
    //            if !jsonFileURLs.isEmpty {
    //                transcriptFile = jsonFileURLs.compactMap { url in
    //                    guard let data = try? Data(contentsOf: url) else { return nil }
    //                    guard let transcript = try? JSONDecoder().decode(textobj.self, from: data) else { return nil }
    //                    return transcript
    //                }
    //
    //                print("transcriptFile[len-1]",transcriptFile[transcriptFile.count-1].name)
    //                print("transcriptFIle[len-2]")
    //                //                if(transcriptFile[transcriptFile.count-1].name != transcriptFile[transcriptFile.count-2].name)
    //                //                {
    //                let transcriptFiletemp = transcriptFile.map { $0 }
    //
    //                //                }
    //                transcriptFile = transcriptFiletemp.sorted()
    //                print("exited successfully")
    //            }
    //        } catch {
    //            print("Error while fetching filenames: \(error.localizedDescription)")
    //        }
    //    }
    //
    //
    //}
    
    
    
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
                    print("submit: transcript",transcript.name)
                    let fileURL = FileManagerHelper.getFileURL(forFilename: transcript.name)
                    print("submit: fileURL",fileURL ?? "Empty")
                    let nameTranscript = "\(transcriptName).transcription"
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
    
    
    
    
    



