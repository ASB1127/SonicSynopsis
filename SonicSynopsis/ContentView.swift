//
//  ContentView.swift
//  SonicSynopsis
//
//  Created by Amit Bal on 3/11/24.
//
import AVFoundation
import SwiftUI

func requestMicrophonePermission() {
    
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
    
        private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
        @available(iOS 15.0, *)
        
        var body: some View {
            VStack {
              
                Spacer()
                Text("Audio Recorder")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer(minLength: 50)
               
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
                   
                    if recordStop == "Record"
                    {
                        do{
                            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let fileName = url.appendingPathComponent("myRCD.m4a")
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
    }


    
    
    #Preview {
        ContentView()
    }


