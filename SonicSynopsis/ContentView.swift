//
//  ContentView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 3/11/24.
//
import AVFoundation
import SwiftUI
import Speech


struct ContentView: View {
    @State var session : AVAudioSession!
    @State var recorder : AVAudioRecorder!
    @State var recordStop = "Record"
    @State var alert = false
    @State private var timeElapsed: TimeInterval = 0
    @State private var isRunning = false
    @State var scaleBigCircle = 0.5
    @State var scaleMediumCircle = 0.5
    @State var scaleSmallCircle = 0.5
    @State var audios : [URL] = []
    @State private var transcription: String = ""
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @available(iOS 15.0, *)
    
    var body: some View {
        VStack {
            
            Spacer()
            Text("Audio Recorder")
                .font(.title)
                .foregroundColor(.white)
            Spacer(minLength: 50)
            List(self.audios, id: \.self){i in
                Text(i.relativeString)
            }
            Text("\(timeString(time:timeElapsed))")
                .font(.system(size: 75))
                .fontWeight(.light)
                .padding()
                .foregroundColor(.white)
            
            
            Spacer(minLength: 150)
            ZStack{
                Circle()
                    .frame(width:250,height:250, alignment: .center)
                    .scaleEffect(CGFloat(scaleBigCircle))
                    .foregroundColor(Color(.systemGray6))
                    .animation(Animation.easeOut(duration: 1).repeatForever(autoreverses: true))
                    .offset(y:-120)
                Circle()
                    .frame(width:200,height:200,alignment: .center)
                    .scaleEffect(CGFloat(scaleMediumCircle))
                    .foregroundColor(Color(.systemGray4))
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
                    .offset(y:-120)
                Circle()
                    .frame(width:150,height:150,alignment: .center)
                    .scaleEffect(CGFloat(scaleSmallCircle))
                    .foregroundColor(Color(.systemGray4))
                    .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
                    .offset(y:-120)
                Circle()
                    .frame(width:100,height:100,alignment: .center)
                    .foregroundColor(Color(.systemIndigo))
                    .overlay(Text(recordStop))
                    .offset(y:-120)
            }
            
            .onTapGesture {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = url.appendingPathComponent("my\(self.audios.count + 1)RCD.m4a")
                self.requestTranscribePermissions()
                self.transcribeLastRecording()
                if recordStop == "Record"
                {
                    do{
                        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let fileName = url.appendingPathComponent("my\(self.audios.count + 1)RCD.m4a")
                        let settings = [
                            AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey : 12000,
                            AVNumberOfChannelsKey : 1,
                            AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue
                        ]
                        
                        self.recorder = try AVAudioRecorder(url: fileName, settings: settings)
                        self.recorder.record()
                        self.recordStop =  "Stop"
                    }
                    catch{
                        print(error.localizedDescription)
                    }
                    scaleBigCircle = 1.2
                    scaleMediumCircle = 1.2
                    scaleSmallCircle = 1.2
                    self.isRunning = true
                }
                else{
                    recordStop = "Record"
                    scaleBigCircle = 1.2
                    scaleMediumCircle = 1.2
                    scaleSmallCircle = 1.2
                    self.isRunning = false
                    self.recorder.stop()
                    self.getAudios()
                    //self.transcribeAudio(url:url)
                    return
                }
                
            }
            .alert(isPresented: self.$alert, content: {
                Alert(title: Text("Error"),message: Text("Enable Access"))
            })
            .onReceive(timer)
            {_ in
                if self.isRunning{
                    
                    do{
                        self.session = AVAudioSession.sharedInstance()
                        self.timeElapsed += 0.1
                        try session.setCategory(.playAndRecord)
                        self.session.requestRecordPermission{ (status) in
                            
                            if !status{
                                self.alert.toggle()
                                
                            }
                            else {
                                self.getAudios()
                            }
                        }
                    }
                    catch
                    {
                        print(error.localizedDescription)
                    }
                }
            }
            
            
            
        }
        .padding()
        .preferredColorScheme(.dark)
    }
    
    private func startTimer(){
        isRunning=true
    }
    private func stopTimer(){
        isRunning=false
    }
    private func resetTimer(){
        isRunning=false
        timeElapsed=0
    }
    private func timeString(time:TimeInterval) -> String{
        let minutes = Int(time)/60
        let seconds = Int(time)%60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d.%02d:%02d",minutes,seconds,milliseconds)
    }
    
    func getAudios(){
        do {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            let result = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .producesRelativePathURLs)
            
            self.audios.removeAll()
            
            for i in result {
                self.audios.append(i)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Good to go!")
                } else {
                    print("Transcription permission was declined.")
                }
            }
        }
    }
    func transcribeAudio(url: URL, completion: @escaping (String?, Error?) -> Void) {
            let recognizer = SFSpeechRecognizer()
            guard let recognizer = recognizer, recognizer.isAvailable else {
                completion(nil, NSError(domain: "SpeechRecognition", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech recognition is not available."]))
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: url)
            
            recognizer.recognitionTask(with: request) { result, error in
                guard error == nil else {
                    completion(nil, error)
                    return
                }
                
                if let result = result, result.isFinal {
                    let transcription = result.bestTranscription.formattedString
                    completion(transcription, nil)
                }
            }
        }
    func transcribeLastRecording() {
            guard let audioURL = audios.last else {
                print("No audio to transcribe")
                return
            }
            
            transcribeAudio(url: audioURL) { transcription, error in
                if let transcription = transcription {
                    self.transcription = transcription
                    print(self.transcription)
                } else if let error = error {
                    print("Transcription error: \(error.localizedDescription)")
                }
            }
        }
}

    
    
    #Preview {
        ContentView()
    }


