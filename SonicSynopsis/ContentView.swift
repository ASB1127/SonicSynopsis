//
//  ContentView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 3/11/24.
//
import AVFoundation
import SwiftUI
import Speech
import GoogleGenerativeAI

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
        print(getMostRecentRecordingFileName())
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
        let oldURL = getDir().appendingPathComponent(oldName)
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


class NewNames: ObservableObject {
    @Published var newNames:[String] = []
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
    
    @State var selectedIndex: Int = 0
   
    
    
    var oldName = ""
    var recorder = KAudioRecorder.shared
    @EnvironmentObject var router: Router
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let audioURL = audios[index]
            let audioName = audioURL.lastPathComponent
            print(audioName)
            audios.remove(at: index)
            recorder.delete(name: audioName)
        }
    }
    func play(at offsets: IndexSet){
        for index in offsets {
            let audioURL = audios[index]
            let audioName = audioURL.lastPathComponent
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
                        var m4aAudios = audios.filter { $0.pathExtension == "m4a" }
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
                                               
                                                let recentFileName = getTranscriptionFileName()
                                                let numbers = recentFileName.components(separatedBy: CharacterSet.decimalDigits.inverted)
                                                                            .joined()
                                                print("numbers: ",numbers)
                                                var cnt = Int(numbers) ?? 0
                                                cnt += 1
                                                let fileName = "transcription\(cnt).txt"
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
                                        guard let index = m4aAudios.firstIndex(of: audios[index]) else { return }
                                        let audioURL = m4aAudios[index]
                                        let audioName = audioURL.lastPathComponent
                                        print(audioName)
                                        m4aAudios.remove(at: index)
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
//                        .sheet(isPresented: $isEditingName) {
//                            EditFileNamesView()
//                                .textField("Enter your name", text: $newName)
//                                .keyboardType(.default)
//                                .presentationDetents([.medium, .large])
//                        }
//                        .onTapGesture {
//                            isEditingName = true
//                        }

//                        .sheet(item: $selectedIndex) { item in
//                                    EditFileNamesView()
//                            TextField("Enter your name",text: $newName)
//                                           .keyboardType(/*@START_MENU_TOKEN@*/.default/*@END_MENU_TOKEN@*/)
//                                           .presentationDetents([.medium,.large])
//                                }
                        
//                        $selectedIndex
                      
                        
                        
                        
                        
                        
                    }
                    Spacer()
                    if(selectedIndex<audios.count)
                    {
                        Text("Selected audio: \(audios[selectedIndex].lastPathComponent)")
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
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
        do {
                try transcription.write(to: fileURL, atomically: true, encoding: .utf8)
                print("Transcription saved to:", fileURL)
            } catch {
                print("Error saving transcription:", error.localizedDescription)
            }
    }
    private func getTranscriptionFileName() ->String
    {

        let fileManager = FileManager.default
        do {
                    let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                    
                    // Filter out files and keep only those with ".txt" extension
                    let textFileURLs = fileURLs.filter { $0.pathExtension == "txt" }
                    
                    // Sort files by creation date, latest first
                    let sortedTextFileURLs = textFileURLs.sorted {
                        (url1, url2) -> Bool in
                        do {
                            let attributes1 = try fileManager.attributesOfItem(atPath: url1.path)
                            let attributes2 = try fileManager.attributesOfItem(atPath: url2.path)
                            if let creationDate1 = attributes1[.creationDate] as? Date,
                               let creationDate2 = attributes2[.creationDate] as? Date {
                                return creationDate1 > creationDate2
                            }
                        } catch {
                            print("Error sorting files:", error.localizedDescription)
                        }
                        return false
                    }
                    
            if let mostRecentFileURL = sortedTextFileURLs.first {
                // Get the filename of the most recent file
                let mostRecentFileName = mostRecentFileURL.lastPathComponent
                print(mostRecentFileName)
                return mostRecentFileName
            } else {
                        print("No transcription files found.")
                    }
                } catch {
                    print("Error loading files from document directory:", error.localizedDescription)
                }
        return ""
    }
                   
                     
                     }
                 




