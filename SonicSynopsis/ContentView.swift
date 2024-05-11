//
//  ContentView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 3/11/24.
//
import AVFoundation
import SwiftUI
import Speech




class KAudioRecorder: NSObject {

    
    static var shared = KAudioRecorder()
    private var audioSession:AVAudioSession = AVAudioSession.sharedInstance()
    private var audioRecorder:AVAudioRecorder!
    private var audioPlayer:AVAudioPlayer = AVAudioPlayer()
    private let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 12000, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    fileprivate var timer:Timer!
    
    var isPlaying:Bool = false
    var isRecording:Bool = false
    var url:URL?
    var time:Int = 0
    var recordName:String?
   
    override init() {
        super.init()

        isAuth()
    }
    
    private func recordSetup() {
        
        var cnt = 0
        
        if let fileName = getMostRecentRecordingFileName(){
            print("fileName = ",fileName)
            let regex = try! NSRegularExpression(pattern: "\\d+(?=\\.)")
            if let match = regex.firstMatch(in: fileName, range: NSRange(fileName.startIndex..., in: fileName)) {
                let digits = String(fileName[Range(match.range, in: fileName)!])
                print("digits= ",digits)
                print("\nclass = KAudioRecorder\n func = recordSetup()\n digits: ",digits)
                cnt=Int(digits) ?? 0
                cnt+=1
            }
            else{
                print("regex failed")
            }
        }

      
        print("\nclass = KAudioRecorder\n func = recordSetup()\n cnt: ",cnt)
        let newFileName = (recordName ?? "sound") + "_\(cnt).m4a"
        print("\nclass = KAudioRecorder\n func = recordSetup()\n newFileName = ",newFileName)
        let newVideoName = getDir().appendingPathComponent(newFileName)
      

        do {
            
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: .defaultToSpeaker)
            
                audioRecorder = try AVAudioRecorder(url: newVideoName, settings: self.settings)
                audioRecorder.delegate = self as AVAudioRecorderDelegate
                audioRecorder.isMeteringEnabled = true
                audioRecorder.prepareToRecord()
            
        } catch {
            print("Recording update error:",error.localizedDescription)
        }
    }
    
    func record() {
        
        recordSetup()
        
        if let recorder = self.audioRecorder {
            if !isRecording {
                
                do {
                    try audioSession.setActive(true)
                    
                    time = 0
                    timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
                
                    recorder.record()
                    isRecording = true
   
                } catch {
                    print("Record error:",error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func updateTimer() {
        
        if isRecording && !isPlaying {
            
            time += 1
            
        } else {
            timer.invalidate()
        }
    }
    
    func stop() {
        
       audioRecorder.stop()
    
        do {
            try audioSession.setActive(false)
        } catch {
            print("stop()",error.localizedDescription)
        }
    }
    
    func play() {
        
        if !isRecording && !isPlaying {
            if let recorder = self.audioRecorder  {
                
                if recorder.url.path == url?.path && url != nil {
                    audioPlayer.play()
                    return
                }
                
                do {
                    
                    audioPlayer = try AVAudioPlayer(contentsOf: recorder.url)
                    audioPlayer.delegate = self as AVAudioPlayerDelegate
                    url = audioRecorder.url
                    audioPlayer.play()
                    
                } catch {
                    print("play(), ",error.localizedDescription)
                }
            }
            
        } else {
            return
        }
    }
    
    func play(name:String) {
        
        let bundle = getDir().appendingPathComponent(name)
        
        if FileManager.default.fileExists(atPath: bundle.path) && !isRecording && !isPlaying {
            
            do {
                
                audioPlayer = try AVAudioPlayer(contentsOf: bundle)
                audioPlayer.delegate = self as AVAudioPlayerDelegate
                audioPlayer.play()
                
            } catch {
                print("play(with name:), ",error.localizedDescription)
            }
            
        } else {
            return
        }
    }
    
    func delete(name:String) {
        
        let bundle = getDir().appendingPathComponent(name)
        let manager = FileManager.default
        
        if manager.fileExists(atPath: bundle.path) {
            
            do {
                try manager.removeItem(at: bundle)
            } catch {
                print("delete()",error.localizedDescription)
            }
            
        } else {
            print("File is not exist.")
        }
    }
    
    func stopPlaying() {
        
        audioPlayer.stop()
        isPlaying = false
    }
    
    private func getDir() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths.first!
    }
    
    @discardableResult
    func isAuth() -> Bool {
        
        var result:Bool = false
        
        AVAudioSession.sharedInstance().requestRecordPermission { (res) in
            result = res == true ? true : false
        }
        
        return result
    }
    
    func getTime() -> String {
        
        var result:String = ""
        
        if time < 60 {
            
            result = "\(time)"
            
        } else if time >= 60 {
            
            result = "\(time / 60):\(time % 60)"
        }
        
        return result
    }
    
//    func getMostRecentRecordingFileName() -> String? {
//        let fileManager = FileManager.default
//        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
//       
//        
//        do {
//            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
//            
//            let audioFiles = fileURLs.filter { $0.pathExtension == "m4a" }
//          
//            let sortedFiles = audioFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
//            print("sortedFiles: ",sortedFiles)
//            if let mostRecentFile = sortedFiles.last {
//                print("\nclass = KAudioRecorder\nfunc = getMostRecentRecordingFileName()\nmostRecentFile.lastPathComponent= ",mostRecentFile.lastPathComponent)
//                return mostRecentFile.lastPathComponent
//            }
//        } catch {
//            print("Error getting file names:", error.localizedDescription)
//        }
//        
//        return nil
//    }
    
    func getMostRecentRecordingFileName() -> String? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            
            let audioFiles = fileURLs.filter { $0.pathExtension == "m4a" }
            
            let sortedFiles = audioFiles.sorted { file1, file2 in
                let components1 = file1.deletingPathExtension().lastPathComponent.components(separatedBy: CharacterSet.decimalDigits.inverted)
                let components2 = file2.deletingPathExtension().lastPathComponent.components(separatedBy: CharacterSet.decimalDigits.inverted)

                for (component1, component2) in zip(components1, components2) {
                    if let number1 = Int(component1), let number2 = Int(component2) {
                        if number1 != number2 {
                            return number1 < number2
                        }
                    } else {
                        if component1 != component2 {
                            return component1 < component2
                        }
                    }
                }

                // If one filename has more components, it should come first
                return components1.count < components2.count
            }
            
            if let mostRecentFile = sortedFiles.last {
                print("\nclass = KAudioRecorder\nfunc = getMostRecentRecordingFileName()\nmostRecentFile.lastPathComponent= ", mostRecentFile.lastPathComponent)
                return mostRecentFile.lastPathComponent
            }
        } catch {
            print("Error getting file names:", error.localizedDescription)
        }
        
        return nil
    }


    
    func changeRecordingFileName(oldName: String,newName: String){
        guard oldName != newName else {
               print("New name is the same as the old name. No renaming needed.")
               return
           }
        let oldURL = getDir().appendingPathComponent(oldName)
        print("oldName = ",oldName)
        print("newNames = ",newName)
        let newURL = getDir().appendingPathComponent(newName)
        print("newURL = ",newURL)
        let manager = FileManager.default
        do {
                try manager.moveItem(at: oldURL, to: newURL)
                print("File renamed successfully.")
            } catch {
                print("Error renaming file:", error.localizedDescription)
            }
    }
    
}



extension KAudioRecorder: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        url = nil
        timer.invalidate()
        print("record finish")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print(error.debugDescription)
    }
}

extension KAudioRecorder: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("playing finish")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print(error.debugDescription)
    }
}


class SharedTranscript: ObservableObject {
   
    @Published var transcription: textobj
    init(transcription: textobj) {
         self.transcription = transcription
     }
   
}



struct textobj:Codable, Identifiable{
var id = UUID()
var name: String
var content: String
func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(content, forKey: .content)
        }

enum CodingKeys: String, CodingKey {
            case name
            case content
        }
}

struct Audio:Identifiable{
    let id = UUID()
    let index:Int
    var name:String
}


    

    
var transcription:String?
struct ContentView: View {
    @State private var session: AVAudioSession!
    @State private var recordStop = "Record"
    @State private var alert = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var isRunning = false
    
    @State private var audios: [URL] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recording = false
    @State private var newName: String = ""
    @State private var isEditingName = false
    //    @State private var selectedAudioIndex: Int?
    //    @State private var newNames: [String] = []
    @State private var fileNames: [String] = []
    //@State private var selectedItem: Int?
    @State private var selectedIndex: Int? = nil
    //@State var selectedIndex: Int = 0
    @State private var audioNames: [Audio] = []
    @State private var selectedAudioIndex: Int?
    @State private var selectedItem: Audio? = nil
    
    @State private var audio:Audio? = nil
    @State var oldName = ""
    //    audioNames = audios.enumerated().map { index, url in
    //        Audio(index: index, name: url.lastPathComponent)
    //    }
    
    
    var recorder = KAudioRecorder.shared
    @EnvironmentObject var router: Router
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    
    func delete(at offsets: IndexSet) {
        var m4audios = audios.filter{$0.lastPathComponent.contains(".m4a")}
        for index in offsets {
            let audioURL = m4audios[index]
            let audioName = audioURL.lastPathComponent
            print(audioName)
            m4audios.remove(at: index)
            recorder.delete(name: audioName)
        }
    }
    func play(at offsets: IndexSet){
        let m4audios = audios.filter{$0.lastPathComponent.contains(".m4a")}
        print("audios: ",m4audios)
        for index in offsets {
            print("m4aaudios: ",m4audios)
            let audioURL = m4audios[index]
            let audioName = audioURL.lastPathComponent
            print("audioName: ",audioName)
            
            recorder.play(name: audioName)
        }
    }
    
    var body: some View {
        
        
        TabView(selection: $router.selectedTab){
            
            NavigationView{
                VStack {
                    
                    Text("Audio Recorder")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    List  {
                        let m4aAudios = audios.filter { $0.pathExtension == "m4a" }
                        
                        ForEach(m4aAudios.indices, id: \.self) { index in
                            //Text(audios[index].lastPathComponent)
                            HStack{
                                
                                Group {
                                    
                                    if index == selectedIndex {
                                        
                                        Text(m4aAudios[index].lastPathComponent)
                                            .background(.red)
                                        Spacer()
                                        
                                    } else {
                                        Text(m4aAudios[index].lastPathComponent)
                                        Spacer()
                                    }
                                }
                                
                            }
                            
                            .contentShape(Rectangle())
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                
                                selectedIndex = index
                                selectedAudioIndex = index
                                selectedItem = Audio(index: index, name: m4aAudios[index].lastPathComponent)
                                print("item: ",selectedItem ?? Audio(index: 0,name: "none"))
                                print("oldName: ",selectedItem?.name ?? "")
                                // EditFileNamesView()
                            }
                            
                            
                            
                            
                            //                            TextField("Enter name", text: $newNames[index])
                            //                                .onSubmit {
                            //                                    print("audios[index] = ",audios[index])
                            //                                    print("newNames[index] = ", newNames[index])
                            //                                    let newName = "\(newNames[index]).m4a"
                            //                                    print("newName = ",newName)
                            //                                    let oldName = audios[index].lastPathComponent
                            //                                    print("oldName = ",oldName)
                            //                                    recorder.changeRecordingFileName(oldName: oldName , newName: newName)
                            //
                            //                                }
                            .swipeActions(allowsFullSwipe: false) {
                                Button {
                                    let audioURL = m4aAudios[index]
                                    requestTranscribePermission()
                                    transcribeFile(audioURL: audioURL) { transcription in
                                        
                                        if let transcription = transcription {
                                            print("Transcription:", transcription)
                                            
                                            let recentFileName = getMostRecentTranscriptionFileName()
                                            print("recentFileName: ",recentFileName)
                                            let numbers = recentFileName.components(separatedBy: CharacterSet.decimalDigits.inverted)
                                                .joined()
                                            print("numbers: ",numbers)
                                            var cnt = Int(numbers) ?? 0
                                            cnt += 1
                                            let fileName = "transcription\(cnt).json"
                                            saveTranscriptionToFile(transcription: transcription, fileName: fileName)
                                            
                                        } else {
                                            print("Transcription is nil.")
                                        }
                                    }
                                } label: {
                                    Label("Transcribe", systemImage: "waveform.path.ecg")
                                }
                                .tint(.indigo)
                                
                                
                                Button(role: .destructive) {
                                    
                                    guard let index = audios.firstIndex(of: m4aAudios[index])
                                    else {
                                        
                                        return
                                    }
                                    
                                    let audioURL = audios[index]
                                    
                                    let audioName = audioURL.lastPathComponent
                                    print(audioName)
                                    audios.remove(at: index)
                                    recorder.delete(name: audioName)
                                    
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                }
                                Button(action: {
                                    guard let index = m4aAudios.firstIndex(of: m4aAudios[index]) else { return }
                                
                                    play(at: IndexSet(integer: index))
                                }) {
                                    Label("Play", systemImage: "play.circle")
                                }
                                
                                
                                
                                
                                
                                
                                
                            }
                            
                            
                            
                            
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let audioURL = m4aAudios[index]
                                let audioName = audioURL.lastPathComponent
                                print(audioName)
                                audios.remove(at: index)
                                recorder.delete(name: audioName)
                            }
                        }
                        
                        
                        
                        
                        .sheet(item: $selectedItem) { selectedItem in
                            // Define oldName here
                            let oldName = selectedItem.name
                            
                            VStack {
                                if #available(iOS 16.0, *) {
                                    TextField("Enter your name", text: $newName)
                                        .keyboardType(.default)
                                        .presentationDetents([.medium, .large])
                                } else {
                                    TextField("Enter your name", text: $newName)
                                        .keyboardType(.default)
                                }
                                EditFileNamesView(audioName: $newName)
                                    .onSubmit {
                                        
                                        print("oldName = ",oldName)
                                        print("newName = ",newName)
                                        recorder.changeRecordingFileName(oldName: oldName, newName: newName)
                                        // users[selectedUserIndex ?? -1].name = name
                                    }
                            }
                        }
                        
                        
                        
                    }
                    
                    Spacer()
                    let m4aAudios = audios.filter { $0.pathExtension == "m4a" }
                    
                    if(selectedIndex ?? 0<m4aAudios.count)
                    {
                        Text("Selected audio: \(m4aAudios[selectedIndex ?? 0].lastPathComponent)")
                    }
                    
                    
                    
                    Spacer(minLength: 80)
                    Text("\(timeString(time: timeElapsed))")
                        .font(.system(size: 75))
                        .fontWeight(.light)
                        .padding()
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 120)
                    
                    ZStack {
                        
                        
                        Circle()
                            .frame(width: 100, height: 100, alignment: .center)
                            .foregroundColor(Color(.systemIndigo))
                            .overlay(Text(recordStop))
                            .offset(y: -120)
                    }
                    .onTapGesture {
                        if recordStop == "Record" {
                            
                            startRecording()
                        } else {
                            stopRecording()
                        }
                    }
                    .alert(isPresented: $alert, content: {
                        Alert(title: Text("Error"), message: Text("Enable Access"))
                    })
                    .onReceive(timer) { _ in
                        if isRunning {
                            timeElapsed += 0.1
                        }
                    }
                    
                    
                    
                    Spacer(minLength: 20)
                    
                    
                        .padding(.top, -70)
                }
                
                
                .onAppear {
                    requestMicrophonePermission()
                    getAudios()
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.825, blendDuration: 0).repeatForever(autoreverses: true)) {
                        recording.toggle()
                    }
                }
                
                
                
                .preferredColorScheme(.dark)
            }
            .tabItem{
                Text("Record")
            }
            .tag(0)
            
            NavigationView{
                ManageTranscriptionsView()
            }
            
            .tabItem{
                Text("Manage Transcriptions")
            }
            .tag(1)
            
            NavigationView{
                Text("Manage Summaries")
                    .font(.title)
                    .navigationTitle(Text("2"))
                
            }
            
            .tabItem{
                Text("Manage Summaries")
            }
            .tag(2)
            
        }
        
        
        
        
    }
    
    
    
    
    
    private func startRecording() {
        do {
            recorder.recordName = "music"
            recorder.record()
            recordStop = "Stop"
            
            isRunning = true
        }
    }
    
    private func stopRecording() {
        recordStop = "Record"
        isRunning = false
        recorder.stop()
        getAudios()
        timeElapsed = 0.0
    }
    
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("User has been granted access")
            } else {
                print("User has not been granted access")
            }
        }
    }
    
    private func getAudios() {
        do {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let result = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)
            audios.removeAll()
            for i in result {
                audios.append(i)
            }
        } catch {
            print("Error getting audios: \(error.localizedDescription)")
        }
    }
    private func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d.%02d:%02d", minutes, seconds, milliseconds)
    }
    
    
    private func getDir() -> URL {
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        
        return paths.first!
    }
    private func transcribeFile(audioURL: URL,  completion: @escaping (String?)-> Void){
        //let bundle = getDir().appendingPathComponent(name.appending(".m4a"))
        let speechRecognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        
        speechRecognizer?.recognitionTask(with: request){
            (result, error) in
            
            print("Recognition task closure entered")
            
            guard let result = result
            else{
                print("ERROR! \(String(describing: error))")
                
                return
            }
            if result.isFinal {
                // print(result.bestTranscription.formattedString)
                transcription = result.bestTranscription.formattedString
                //print("Transcription is final:", transcription ?? "")
                completion(transcription)
                //return result.bestTranscription.formattedString
            }
            
        }
        
    }
    private func requestTranscribePermission(){
        SFSpeechRecognizer.requestAuthorization{ authStatus in DispatchQueue.main.async{
            if authStatus == .authorized
            {
                print("Transcription Ready TO Go")
            }
            else{
                print("Transcription permission was declined.")
            }
        }
        }
    }
    private func saveTranscriptionToFile(transcription: String, fileName:String){
        print("fileName: ",fileName)
        var data = Data()
        let transcript = textobj.init(name: fileName, content: transcription)
        
        do{
            
            data = try JSONEncoder().encode(transcript)
            print("Encoded JSON data:", String(data: data, encoding: .utf8) ?? "Failed to decode data")
            //DEBUG comment these two lines
            let transcriptFinal = try JSONDecoder().decode(textobj.self, from: data)
            print("\nDecoded Transcript:", transcriptFinal)
        }
        catch{
            
            print("Error encoding transcript: \(error)")
        }
        
        
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("documentsdir: \n",documentsDirectory)
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        print("fileURL: ", fileURL)
        do{
            try data.write(to: fileURL)
            print("Data saved successfully to \(fileURL)")
        }
        catch{
            print("Error saving data: \(error)")
        }
        
        //        if FileManager.default.fileExists(atPath: fileURL.path) {
        //            // Read the data from the file
        //            do {
        //                let data = try Data(contentsOf: fileURL)
        //
        //                // Decode the data into your struct
        //                let transcriptFinal = try JSONDecoder().decode(transcriptionObj.self, from: data)
        //
        //                // Now you have the struct instance
        //                print("Retrieved transcript:", transcript)
        //            } catch {
        //                print("Error reading or decoding data:", error)
        //            }
        //        } else {
        //            print("File does not exist at path:", fileURL.path)
        //        }
        //        do {
        //                try transcription.write(to: fileURL, atomically: true, encoding: .utf8)
        //                print("Transcription saved to:", fileURL)
        //            } catch {
        //                print("Error saving transcription:", error.localizedDescription)
        //            }
    }
    private func getMostRecentTranscriptionFileName() -> String {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var mostRecentFileURL: URL?
        var highestCount = 0
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent
                
                // Check if the filename adheres to the expected pattern and contains a number
                if fileName.hasPrefix("transcription") && fileName.hasSuffix(".json") {
                    let countString = fileName.replacingOccurrences(of: "transcription", with: "").replacingOccurrences(of: ".json", with: "")
                    if let count = Int(countString), count > highestCount {
                        highestCount = count
                        mostRecentFileURL = fileURL
                    }
                }
            }
            
            // If no valid filenames found, set most recent filename to have count 0
            if mostRecentFileURL == nil {
                let defaultFileName = "transcription0.json"
                mostRecentFileURL = documentsURL.appendingPathComponent(defaultFileName)
            }
        } catch {
            print("Error while enumerating files:", error)
        }
        
        return mostRecentFileURL!.lastPathComponent
    }

}




