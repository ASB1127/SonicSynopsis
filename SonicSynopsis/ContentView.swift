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
        if let fileName = getMostRecentRecordingFileName(){
            var numericString = String(fileName.filter { $0.isNumber })
            print(fileName)
            if let numericValue = Int(numericString) {
                cnt = numericValue + 1
            }
        }
      
        print("cnt: ",cnt)
        let newFileName = (recordName ?? "sound") + "_\(cnt).rec"
        print(newFileName)
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
    
    func getMostRecentRecordingFileName() -> String? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let audioFiles = fileURLs.filter { $0.pathExtension == "rec" }
            let sortedFiles = audioFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
            
            if let mostRecentFile = sortedFiles.last {
                return mostRecentFile.lastPathComponent
            }
        } catch {
            print("Error getting file names:", error.localizedDescription)
        }
        
        return nil
    }
    
    func changeRecordingFileName(oldName: String,newName: String){
        let oldURL = getDir().appendingPathComponent(oldName)
        let newURL = getDir().appendingPathComponent(newName)
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






    

    
var transcription:String?
struct ContentView: View {
    @State private var session: AVAudioSession!
    @State private var recordStop = "Record"
    @State private var alert = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var isRunning = false
    @State private var scaleBigCircle = 0.5
    @State private var scaleMediumCircle = 0.5
    @State private var scaleSmallCircle = 0.5
    @State private var audios: [URL] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recording = false
    @State private var newName: String = ""
    @State private var isEditingName = false
    @State private var selectedAudioIndex: Int?
    @State private var editedAudioNames: [String] = []
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
                    
                    
                    
                    List {
                        ForEach(audios, id: \.self) { audio in
                          
                            TextField("Enter name", text: Binding(
                                get: {
                                    if let index = audios.firstIndex(of: audio), index < editedAudioNames.count {
                                        return editedAudioNames[index]
                                    } else {
                                        return ""
                                    }
                                },
                                set: { newName in
                                    if let index = audios.firstIndex(of: audio), index < editedAudioNames.count {
                                        editedAudioNames[index] = newName
                                    }
                                }
                            ))
                                .swipeActions(allowsFullSwipe: false) {
                                    Button {
                                        guard let index = audios.firstIndex(of: audio) else { return }
                                        let audioURL = audios[index]
                                        requestTranscribePermission()
                                        transcribeFile(audioURL:audioURL ){ transcription in
                                        if let transcription = transcription {
                                        print("Transcription:", transcription)
                                        }
                                        else{
                                        print("Transcription is nil.")
                                        }
                                        }
                                        
                                    } label: {
                                        Label("Transcribe", systemImage: "waveform.path.ecg")
                                    }
                                    .tint(.indigo)
                                    
                                    Button(role: .destructive) {
                                        guard let index = audios.firstIndex(of: audio) else { return }
                                        let audioURL = audios[index]
                                        let audioName = audioURL.lastPathComponent
                                        print(audioName)
                                        audios.remove(at: index)
                                        recorder.delete(name: audioName)
                                        
                                    } label: {
                                        Label("Delete", systemImage: "trash.fill")
                                    }
                                    Button(action: {
                                                    guard let index = audios.firstIndex(of: audio) else { return }
                                                    play(at: IndexSet(integer: index))
                                                }) {
                                                    Label("Play", systemImage: "play.circle")
                                                }
                                                
                                                
                                            }
                               
                          
                            
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let audioURL = audios[index]
                                let audioName = audioURL.lastPathComponent
                                print(audioName)
                                audios.remove(at: index)
                                recorder.delete(name: audioName)
                            }
                        }
                        .onAppear {
                               editedAudioNames = audios.map { $0.lastPathComponent }
                           }
                        
                      
                        
                        
                        
                        
                        
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
                     scaleBigCircle = 1
                     scaleMediumCircle = 1
                     scaleSmallCircle = 1
                     isRunning = true
                     }
                     }
                     
                     private func stopRecording() {
                     recordStop = "Record"
                     scaleBigCircle = 1
                     scaleMediumCircle = 1
                     scaleSmallCircle = 1
                     isRunning = false
                     recorder.stop()
                     getAudios()
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
                     guard let result = result
                     else{
                     print("ERROR! \(String(describing: error))")
                     
                     return
                     }
                     if result.isFinal {
                     print(result.bestTranscription.formattedString)
                     transcription = result.bestTranscription.formattedString
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
                     
                     
                     }
                 




