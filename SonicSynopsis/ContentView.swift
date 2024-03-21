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
       
        let newVideoName = getDir().appendingPathComponent(recordName?.appending(".m4a") ?? "sound.m4a")
        
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
        
        let bundle = getDir().appendingPathComponent(name.appending(".m4a"))
        
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
        
        let bundle = getDir().appendingPathComponent(name.appending(".m4a"))
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
    
}//

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

    
    var recorder = KAudioRecorder.shared

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Spacer()
            Text("Audio Recorder")
                .font(.title)
                .foregroundColor(.white)
            Spacer(minLength: 50)
            List(audios, id: \.self) { audio in
                Text(audio.lastPathComponent)
            }
            Text("\(timeString(time: timeElapsed))")
                .font(.system(size: 75))
                .fontWeight(.light)
                .padding()
                .foregroundColor(.white)

            Spacer(minLength: 150)
            ZStack {
                Circle()
                    .frame(width: 250, height: 250, alignment: .center)
                    .scaleEffect(CGFloat(scaleBigCircle))
                    .foregroundColor(Color(.systemGray6))
                    .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: true))
                    .offset(y: -120)
                Circle()
                    .frame(width: 200, height: 200, alignment: .center)
                    .scaleEffect(CGFloat(scaleMediumCircle))
                    .foregroundColor(Color(.systemGray4))
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
                    .offset(y: -120)
                Circle()
                    .frame(width: 150, height: 150, alignment: .center)
                    .scaleEffect(CGFloat(scaleSmallCircle))
                    .foregroundColor(Color(.systemGray4))
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
                    .offset(y: -120)
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
            
            Button(action: {
                playLastRecording()
            }) {
                Text("Play Last Recording")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            .disabled(audios.isEmpty) // Disable the button if there are no recordings
        }
        .padding()
        .preferredColorScheme(.dark)
        .onAppear {
            requestMicrophonePermission()
        }
    }

    private func startRecording() {
        do {
            /*
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = url.appendingPathComponent("my\(audios.count + 1)RCD.m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]*/
           
            recorder.recordName = "music"
            recorder.record()
            recordStop = "Stop"
            scaleBigCircle = 1.2
            scaleMediumCircle = 1.2
            scaleSmallCircle = 1.2
            isRunning = true
        } catch {
            print(error.localizedDescription)
        }
    }

    private func stopRecording() {
        recordStop = "Record"
        scaleBigCircle = 1.2
        scaleMediumCircle = 1.2
        scaleSmallCircle = 1.2
        isRunning = false
        recorder.stop()
        getAudios()
    }

    private func playLastRecording() {
        recorder.play()
        recorder.play(name:"music") // Recorded name
    }

    private func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d.%02d:%02d", minutes, seconds, milliseconds)
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
            print(error.localizedDescription)
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
        }}
    }
    
    private func transcribeFile(){
        
    }
    
    
    private func requestMicrophonePermission() {
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
               
                
                
                // The user granted access. Present recording interface.
            } else {
                
                // Display a SwiftUI view containing the message
                
                // Present message to user indicating that recording
                // can't be performed until they change their preference
                // under Settings -> Privacy -> Microphone
                
            }
        }
        
    }
}
