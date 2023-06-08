//
//  AudioSteram.swift
//  TranscriptStream
//
//  Created by Yuri Fukuda on 6/1/23.
//

import Foundation
import AVFoundation

class AudioStream {
    var audioEngine:AVAudioEngine!;
    var audioInputNode:AVAudioInputNode!;
    var audioInputFormat:AVAudioFormat!;
    var formatConverter:AVAudioConverter!;
    var onData: (( NSData ) -> Void)!;
    let sampleRate = 44100;
    let convertedSampleRate = 16000
    private let conversionQueue = DispatchQueue(label: "conversionQueue")

    init(){
        // Create an AVAudioEngine instance
    }

    func setup(){
        audioEngine = AVAudioEngine();

        // Create an AVAudioInputNode for capturing audio from the microphone
        audioInputNode = audioEngine.inputNode
        let bus = 0
        
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: Double(convertedSampleRate),
            channels: 1,
            interleaved: true
          )
        audioInputFormat = audioInputNode.outputFormat(forBus: bus)
        //audioEngine.connect(audioInputNode, to: audioEngine.mainMixerNode, format: desiredFormat)
        guard let formatConverter =  AVAudioConverter(from:audioInputFormat, to: recordingFormat!) else {
          return
        }
//
        audioInputNode.installTap(onBus: bus, bufferSize: AVAudioFrameCount(3200), format:audioInputFormat) {
            (pcmBuffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in

            self.conversionQueue.async {
                
                let inputBlock: AVAudioConverterInputBlock = { inNumPackets, onStatus in
                    onStatus.pointee = .haveData
                    return pcmBuffer
                }

            let sampleRateRatio = Double( self.convertedSampleRate ) / self.audioInputFormat.sampleRate
                let outputFrameCapacity = AVAudioFrameCount(Double(pcmBuffer.frameCapacity) * sampleRateRatio)

                guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: outputFrameCapacity) else {
                    return
                }

                var error: NSError? = nil
                // convert input format to output format
                formatConverter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

                guard let data = outputBuffer.data() else {
                    print("no data ")
                    return
                }
                self.onData( data as NSData );

//
//
//
//                //=============
//
//                // An AVAudioConverter is used to convert the microphone input to the format required for the model.(pcm 16)
//                let pcmBuffer = AVAudioPCMBuffer(pcmFormat: recordingFormat!, frameCapacity: AVAudioFrameCount(recordingFormat!.sampleRate * 2.0))
//                var error: NSError? = nil
////
//                let inputBlock: AVAudioConverterInputBlock = {inNumPackets, outStatus in
//                    outStatus.pointee = AVAudioConverterInputStatus.haveData
//                    return buffer
//                }
////
//                formatConverter.convert(to: pcmBuffer!, error: &error, withInputFrom: inputBlock)
////
//                if error != nil {
//                    print(error!.localizedDescription)
//                } else if ( pcmBuffer != nil ) {
////                  if ( buffer != nil ) {
////                    guard let data = self.convertPCMBufferToNSData( buffer ) else {
////                        print( "No Data " );
////                        return;
////                    }
//                    //analyze the audio data here
//                    guard let data = self.convertPCMBufferToNSData( pcmBuffer! ) else {
//                        print("no data ")
//                        return
//                    }
//                    self.onData( data );
//                 }
            }/* end of async */
        }/* end of tap */

    }
    
    func getInputFormat() -> AVAudioInputNode {
            return audioInputNode
    }
    
    func start( _ onData: @escaping ( NSData ) -> Void ){
        self.onData = onData;
        try! audioEngine.start()
        // Start the microphone input
        audioInputNode.volume = 1.0 // Adjust the volume as needed
        audioInputNode.pan = 0.0 // Adjust the pan as needed
    }
    
    func stop(){
        audioEngine.stop()
    }

    
    func convertPCMBufferToNSData(_ buffer: AVAudioPCMBuffer) -> NSData? {
        buffer.data() as NSData?
    }
}
