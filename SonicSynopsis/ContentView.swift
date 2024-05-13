//
//  ContentView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 3/11/24.
//
import AVFoundation
import SwiftUI
import Speech



//Class KAudioRecorder Source From: https://github.com/KenanAtmaca/KAudioRecorder
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
        
        let cnt = 0
        
       

      
        print("\nclass = KAudioRecorder\n func = recordSetup()\n cnt: ",cnt)
        let newFileName = getMostRecentRecordingFileName()
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

    
    func getMostRecentRecordingFileName()-> String {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var mostRecentFileURL: URL?
      
        var maxCount = -1
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
           
            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent
           
           
                let pattern = "music_([0-9]+).m4a"
                
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
            let defaultFileName = "music_1.m4a"
            mostRecentFileURL = documentsURL.appendingPathComponent(defaultFileName)
        }else{
            maxCount+=1
            print("getMostRecentAudioFileName() maxCount:",maxCount)
            let defaultFileName = "music_\(maxCount).m4a"
            mostRecentFileURL = documentsURL.appendingPathComponent(defaultFileName)
        }
        
        return mostRecentFileURL!.lastPathComponent
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

extension URL: Comparable {
    public static func < (lhs: URL, rhs: URL) -> Bool {
        if(lhs.containsNumber() == false && rhs.containsNumber()==false && lhs.absoluteString != rhs.absoluteString)
        {
            print("lhs < rhs")
            print("lhs:",lhs.absoluteString)
            print("rhs:",rhs.absoluteString)
            return lhs.absoluteString < rhs.absoluteString
        }
        else {
            let lhsNumber = lhs.extractNumber() ?? 0
            let rhsNumber = rhs.extractNumber() ?? 0
            return lhsNumber < rhsNumber
        }
    }
    
    func containsNumber() -> Bool {
            
            let pattern = "\\d+"
            
            do {
               
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                
             
                return regex.firstMatch(in: absoluteString, options: [], range: NSRange(location: 0, length: absoluteString.count)) != nil
            } catch {
                
                print("Error creating regex: \(error)")
                return false
            }
        }
    
    public func extractNumber() -> Int? {
        guard let components = NSURLComponents(url: self, resolvingAgainstBaseURL: true),
                      let path = components.path else {
                    return nil
                }
                
             
                let lastPathComponent = NSString(string: path).lastPathComponent
                
          
                let digits = lastPathComponent.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                
              
                return Int(digits)
            }
    
}


class SharedTranscript: ObservableObject {
   
    @Published var transcription: textobj
    init(transcription: textobj) {
         self.transcription = transcription
     }
   
}



struct textobj:Codable, Identifiable,Comparable{
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
    
    static func < (lhs: textobj, rhs: textobj) -> Bool {
        if (lhs.containsNumber() == false && rhs.containsNumber() && lhs.name != rhs.name) {
               return lhs.name < rhs.name
           } else {
            
               let lhsNumber = lhs.extractNumber()
               let rhsNumber = rhs.extractNumber()
               return lhsNumber < rhsNumber
           }
       }
    
    private func containsNumber() -> Bool {
        let range = NSRange(location: 0, length: name.utf16.count)
        let regex = try! NSRegularExpression(pattern: "\\d")
        return regex.firstMatch(in: name, options: [], range: range) != nil
    }

    
    static func == (lhs: textobj, rhs: textobj) -> Bool {
            return lhs.name == rhs.name && lhs.content == rhs.content
        }
    private func extractNumber() -> Int {
           let components = name.components(separatedBy: CharacterSet.decimalDigits.inverted)
           return components.compactMap { Int($0) }.first ?? 0
       }
}


struct Audio:Identifiable{
    let id = UUID()
    let index:Int
    var name:String
}


    

    
var summary:String?
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
  
    @State private var selectedIndex: Int? = nil
    @State private var audioNames: [Audio] = []
    @State private var selectedAudioIndex: Int?
    @State private var selectedItem: Audio? = nil
    @State private var shouldRedrawTranscriptView = false
    @State private var shouldRedrawSummaryView = false
 
 
    
    
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
                            HStack{
                                
                                Group {
                                    
                                    if index == selectedIndex {
                                        
                                        Text(m4aAudios[index].lastPathComponent)
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
                            
                            }
                            
                            .swipeActions(allowsFullSwipe: false) {
                                Button {
                                    let audioURL = m4aAudios[index]
                                    requestTranscribePermission()
                                    transcribeFile(audioURL: audioURL) { transcription in
                                        
                                        if let transcription = transcription {
                                            print("Transcription:", transcription)
                                            
                                            let recentFileName = getMostRecentTranscriptFileName()
                                            print("recentFileName: ",recentFileName)
                                            
                                            saveTranscriptionToFile(transcription: transcription, fileName: recentFileName)
                                            
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
                            
                            EditFileNamesView(audioName: $newName,initialName: m4aAudios[selectedAudioIndex!].lastPathComponent, recorder: recorder,m4audios: m4aAudios,index: selectedItem.index)
                                .onDisappear {
                                       // Perform actions when the sheet is dismissed
                                      getAudios()
                                   }
                            VStack {
                                
                                if #available(iOS 16.0, *) {
                                   
                                    HStack{
                                        Spacer(minLength: 30)
                                        TextField("Enter your name", text: $newName)
                                            .keyboardType(.default)
                                            .presentationDetents([.medium, .large])
                                    }
                                    .onSubmit{
                                        let m4audios = audios.filter { $0.pathExtension == "m4a" }
                                        var oldName = String(m4audios[selectedIndex!].lastPathComponent)
                                        oldName = "\(oldName)"
                                        var finalName = "\(newName).m4a"
                                        recorder.changeRecordingFileName(oldName: oldName, newName: finalName)
                                        finalName=""
                                       getAudios()
                                    }
                                } else {
                                 
                                    HStack{
                                        Spacer(minLength: 30)
                                        TextField("Enter your name", text: $newName)
                                            .keyboardType(.default)
                                    }
                                    .onSubmit{
                                        let m4audios = audios.filter { $0.pathExtension == "m4a" }
                                        var oldName = String(m4audios[selectedIndex!].lastPathComponent)
                                        oldName = "\(oldName)"
                                        var finalName = "\(newName).m4a"
                                        recorder.changeRecordingFileName(oldName: oldName, newName: finalName)
                                        finalName=""
                                       getAudios()
                                    }
                                }
                               
                                   
                            }
                        }
                        
                        
                        
                    }
                    
                    Spacer(minLength: 120)
                
                    

                    Text("\(timeString(time: timeElapsed))")
                        .font(.system(size: 75))
                        .fontWeight(.light)
                        .padding()
                        .foregroundColor(.white)
                    
//                    Spacer(minLength: 210)
                    
                    ZStack {
                        
                        
                        Circle()
                            .frame(width: 100, height: 100, alignment: .center)
                            .foregroundColor(Color(.systemIndigo))
                            .overlay(Text(recordStop))
                            .offset(y: -30)
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
                    
                    
                    
               
                    
                    
                        .padding(.top, -200)
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
                ManageTranscriptionsView( shouldRedrawTranscriptionView: $shouldRedrawTranscriptView)
            }
            
            .tabItem{
                Text("Manage Transcriptions")
            }
            .tag(1)
            
            NavigationView{
                ManageSummariesView(shouldRedrawSummaryView:$shouldRedrawSummaryView )
                
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
            audios = audios.sorted()
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
                summary = result.bestTranscription.formattedString
                //print("Transcription is final:", transcription ?? "")
                completion(summary)
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
            shouldRedrawTranscriptView.toggle()
            print("shouldRedrawChild:",shouldRedrawTranscriptView)
            print("Data saved successfully to \(fileURL)")
        }
        catch{
            print("Error saving data: \(error)")
        }
        
        
    }
   
    private func getMostRecentTranscriptFileName() -> String {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var mostRecentFileURL: URL?
  
        var maxCount = -1
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
           
            for fileURL in fileURLs {
                let fileName = fileURL.lastPathComponent
                
             
                let pattern = "transcript([0-9]+).transcription"
                
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
                        print("getMostRecentTranscriptFileName() count=",count, "maxCount=",maxCount)
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
            let defaultFileName = "transcript1.transcription"
            mostRecentFileURL = documentsURL.appendingPathComponent(defaultFileName)
        }else{
            maxCount+=1
            print("getMostRecentTranscriptFileName() maxCount:",maxCount)
            let defaultFileName = "transcript\(maxCount).transcription"
            mostRecentFileURL = documentsURL.appendingPathComponent(defaultFileName)
        }
        
        return mostRecentFileURL!.lastPathComponent
    }
    
    
    
    
}






