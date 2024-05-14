//
//  ManageSummariesView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 5/10/24.
//

import SwiftUI

struct ManageSummariesView: View {
    @State private var summary:textobj? = nil
    @ObservedObject var folder = Folder(filter: "summary")
    @State private var summaryFile: [textobj] = []
    @State var name:String = ""
    @State private var selectedIndex:Int?
    @State private var selectedSummary: textobj? = nil
    @State var summaryContent:String = ""
 
    
    var body: some View {
        VStack {
            List {
                ForEach(folder.transcriptFile.indices, id: \.self) { index in
                    
                    HStack {
                        Text(folder.transcriptFile[index].name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedIndex = index
                        selectedSummary = folder.transcriptFile[index]
                    }
                    
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedIndex = index
                            
                            FileManagerHelper.deleteTextFile(fileName:folder.transcriptFile[selectedIndex ?? -1].name )
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                        .tint(.red)
                    }
                    
                }
               
            }
         
            .preferredColorScheme(.dark)
        }
        .sheet(item: $selectedSummary) { selectedSummary in
            
            EditSummariesView(
                summaryName: $name,
                summaryContent: $summaryContent,
                initialName: selectedSummary.name,
                summaryFile:folder.transcriptFile,
                fileManagerHelper: FileManagerHelper.init(),
                summary: selectedSummary
            )
            .onDisappear {
                   // Perform actions when the sheet is dismissed
                var res = folder.loadFiles(pathExtension: "summary")
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
                            FileManagerHelper.saveFileName(transcript: folder.summaryFile[selectedIndex!], newName: nameSummary, jsonFile: &folder.summaryFile)
                            
                            
                            
                            
                            
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
    
   
    
    struct EditSummariesView: View {
        
        @Environment (\.dismiss) var submit
        @Binding var summaryName: String
        @Binding var summaryContent: String
        @State var initialName:String
        @State var summaryFile:[textobj] = []
        var fileManagerHelper:FileManagerHelper
        var summary:textobj
 
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

