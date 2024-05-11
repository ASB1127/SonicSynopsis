//
//  ManageSummariesView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 5/10/24.
//

import SwiftUI

struct ManageSummariesView: View {
    @State private var summary:textobj? = nil
   
    @State private var jsonFile: [textobj] = []
    @State var name:String = ""
    @State private var selectedIndex:Int?
//    @State private var transcriptStructs: [transcriptionObj] = []
    @State private var selectedSummary: textobj? = nil
    @State var summaryContent:String = ""
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    ManageSummariesView()
}
