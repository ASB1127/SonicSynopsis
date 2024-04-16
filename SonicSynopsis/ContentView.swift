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
    var recorder = KAudioRecorder.shared
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                           Text("Audio Recorder")
                               .font(.title)
                               .foregroundColor(.white)
                           Spacer(minLength: 50)
                          
                /*
                           List(audios, id: \.self) { audio in
                               Text(audio.lastPathComponent)
                           }*/
                           
                           Text("\(timeString(time: timeElapsed))")
                               .font(.system(size: 75))
                               .fontWeight(.light)
                               .padding()
                               .foregroundColor(.white)
                           
                           Spacer(minLength: 120)
                            
                           ZStack {
                               
                               Circle()
                                              .stroke(lineWidth: recording ? 4 : 0)
                                         
                                              .animation(.spring(), value: recording)
                                              .frame(width: 240, height: 240)
                                              .foregroundStyle(Color(.systemGray6))
                                              .scaleEffect(recording ? 1 : 0.5)
                                              .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.86, blendDuration: 0.25).repeatForever(autoreverses: false), value: recording)
                                          
                                          // Middle
                                          Circle()
                                              .frame(width: 160, height: 160)
                                              .foregroundStyle(Color(.systemGray))
                                              .scaleEffect(recording ? 1 : 0.5)
                                              .opacity(recording ? 0.6 : 0)
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
                                   .background(Color(red: 0.69, green: 0.61, blue: 0.85))
                                   .cornerRadius(10)
                           }
                           .padding(.top, -100) // Adjust bottom padding to move the button closer
                                           
                            Spacer(minLength: 20)
               
                           
                NavigationLink(destination: ManageRecordingsView()) {
                    Text("Manage Recordings")
                }
                .padding(.top, -50) 
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

    private func playLastRecording() {
        do {
            recorder.play()
            recorder.play(name: "music") // Recorded name
        }
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
}




