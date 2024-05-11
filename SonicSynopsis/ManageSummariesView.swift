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
            .preferredColorScheme(.dark)
        }
        .sheet(item: $selectedSummary) { selectedSummary in
            
            EditSummariesView(
                summaryName: $name,
                summaryContent: $summaryContent,
                initialName: selectedSummary.name
            )
           
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
                            //                        saveFileName(transcript: jsonFile[selectedIndex!], newName: name)
                            
                            FileManagerHelper.changeFileName(fileURL: fileURL!, newName: nameSummary)
                            FileManagerHelper.saveFileName(transcript: summaryFile[selectedIndex!], newName: nameSummary, jsonFile: &summaryFile)
                            //                        deleteFileName(fileURL: fileURL!, filename: oldName)
                            //                        jsonFile[selectedIndex ?? -1].name=name
                            
                            
                            
                            
                        }
                }
                
                
            } else {
                HStack{
                    Spacer(minLength: 20)
                    TextField("Enter your name",text: $name)
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
                }
            } catch {
                print("Error while fetching filenames: \(error.localizedDescription)")
            }
        }
    
    struct EditSummariesView: View {
        
        // MARK: - Properties
        @Environment (\.dismiss) var dismiss
        @Binding var summaryName: String
        @Binding var summaryContent: String
        @State var initialName:String
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
                    Button("Dismiss") {
                        dismiss()
                        
                        summaryName=""
                    }
                    .onChange(of: summaryName) { newName in
                        if !newName.isEmpty {
                            initialName = ""
                        }
                    }
                    .onDisappear{
                        summaryName=""
                    }
                    
                
            }
         
        }
        
    }
        
    
    }

