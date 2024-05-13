//
//  ManageSummariesView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 5/10/24.
//

import SwiftUI

struct ManageSummariesView: View {
    @State private var summary:textobj? = nil
    @State private var summaryFile: [textobj] = []
    @State var name:String = ""
    @State private var selectedIndex:Int?
    @State private var selectedSummary: textobj? = nil
    @State var summaryContent:String = ""
    @Binding var shouldRedrawSummaryView: Bool
    var body: some View {
        VStack {
            List {
                ForEach(summaryFile.indices, id: \.self) { index in
                    
                    HStack {
                        Text(summaryFile[index].name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = index
                        selectedSummary = summaryFile[index]
                    }
                    
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedIndex = index
                            
                            FileManagerHelper.deleteTextFile(fileName:summaryFile[selectedIndex ?? -1].name )
                            loadFiles(pathExtension: "summary")
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        .tint(.red)
                    }
                    
                }
               
            }
            .onAppear {
                // Load filenames and transcripts
                loadFiles(pathExtension: "summary")
            }
            .onChange(of: shouldRedrawSummaryView) { newValue in
                            if newValue {
                                loadFiles(pathExtension: "summary")
                                shouldRedrawSummaryView = false
                            }
                        }
            .preferredColorScheme(.dark)
        }
        .sheet(item: $selectedSummary) { selectedSummary in
            
            EditSummariesView(
                summaryName: $name,
                summaryContent: $summaryContent,
                initialName: selectedSummary.name,
                summaryFile:summaryFile,
                fileManagerHelper: FileManagerHelper.init(),
                summary: selectedSummary
            )
            .onDisappear {
                   // Perform actions when the sheet is dismissed
                   loadFiles(pathExtension: "summary")
               }
           
            if #available(iOS 16.0, *) {
                HStack {
                    Spacer(minLength: 20)
                    TextField("\(selectedSummary.name)",text: $name)
                        .keyboardType(/*@START_MENU_TOKEN@*/.default/*@END_MENU_TOKEN@*/)
                        .presentationDetents([.medium,.large])
                        .onAppear {
                            
                            summaryContent = selectedSummary.content
                        }
                        .onSubmit{
                            let fileURL = FileManagerHelper.getFileURL(forFilename: summaryFile[selectedIndex ?? -1].name)
                            
                            print("newName: ",name)
                            
                            print("oldName: ",summaryFile[selectedIndex ?? -1].name)
                            print("jsonFiles: ",summaryFile)
                            let nameSummary = "\(name).summary"
                            FileManagerHelper.changeFileName(fileURL: fileURL!, newName: nameSummary)
                            FileManagerHelper.saveFileName(transcript: summaryFile[selectedIndex!], newName: nameSummary, jsonFile: &summaryFile)
                            
                            
                            
                            
                            
                        }
                }
                
                
            } else {
                HStack{
                    Spacer(minLength: 20)
                    TextField("\(selectedSummary.name)",text: $name)
                        .keyboardType(/*@START_MENU_TOKEN@*/.default/*@END_MENU_TOKEN@*/)
                        .onAppear {
                            
                            summaryContent = selectedSummary.content
                        }
                        .onSubmit{
                            let fileURL = FileManagerHelper.getFileURL(forFilename: summaryFile[selectedIndex ?? -1].name)
                            
                            print("fileURL: ",fileURL!)
                            print("name: ",summaryFile[selectedIndex ?? -1].name)
                            summaryFile[selectedIndex ?? -1].name=name
                            
                            FileManagerHelper.changeFileName(fileURL: fileURL!, newName: name)
                            
                        }
                }
            
            }
            
            
        }
    }
    
    private func loadFiles(pathExtension:String) {
           print("loadFiles: pathExtension",pathExtension)
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                
                let summaryFileURLs = fileURLs.filter { $0.pathExtension == pathExtension }
                print("loadFiles: summaryFileURLs",summaryFileURLs)
                if !summaryFileURLs.isEmpty {
                    summaryFile = summaryFileURLs.compactMap { url in
                        guard let data = try? Data(contentsOf: url) else { return nil }
                        guard let transcript = try? JSONDecoder().decode(textobj.self, from: data) else { return nil }
                        return transcript
                    }
                    print("loadFiles summaryFile: ",summaryFile)
                    summaryFile = summaryFile.map { $0 }
                    summaryFile = summaryFile.sorted()
                }
            } catch {
                print("Error while fetching filenames: \(error.localizedDescription)")
            }
        }
    
    struct EditSummariesView: View {
        
        // MARK: - Properties
        @Environment (\.dismiss) var submit
        @Binding var summaryName: String
        @Binding var summaryContent: String
        @State var initialName:String
        @State var summaryFile:[textobj] = []
        var fileManagerHelper:FileManagerHelper
        var summary:textobj
        // MARK: - Body
 
        var body: some View {
                Spacer(minLength: 20)
                VStack{
                    HStack{
                        Text("\(initialName)\(summaryName)")
                            .font(.title)
                            .fontWeight(.bold)
                           
                    }
                    .padding(.horizontal)
                    Spacer()
                    ScrollView {
                        Text("\(summaryContent)")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                   
                    .onChange(of: summaryName) { newName in
                        if !newName.isEmpty {
                            initialName = ""
                        }
                    }
                    Button("Submit") {
                        submit()
                        let fileURL = FileManagerHelper.getFileURL(forFilename: summary.name)
                        let nameSummary = "\(summaryName).summary"
                        print("summary: ",summaryName)
                        FileManagerHelper.changeFileName(fileURL: fileURL!, newName: nameSummary)
                        FileManagerHelper.saveFileName(transcript: summary , newName: nameSummary, jsonFile: &summaryFile)
                        summaryName=""
                    }
                    .onDisappear{
                        summaryName=""
                    }
                    
                
            }
         
        }
        
    }
        
    
    }

