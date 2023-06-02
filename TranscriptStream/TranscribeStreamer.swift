//
//  AudioStreamer.swift
//  TranscriptStream
//
//  Created by Yuri Fukuda on 6/1/23.
//

import Foundation
import AWSTranscribeStreaming
import AWSRuntime
import AVFAudio

typealias ErrorCallback = ( String)-> Void;
typealias onTextCallback = ( String)-> Void;

class AudioStreamer:NSObject, AWSTranscribeStreamingClientDelegate {
    
    private let transcriptKey = "TranscriptKey"
    private var apiKey:String;
    private var apiSecret:String;
    private var onError:ErrorCallback?;
    private var onText:onTextCallback?;
    private var transcribeStreamingClient: AWSTranscribeStreaming;
    private var audioStream: AudioStream
    private var request: AWSTranscribeStreamingStartStreamTranscriptionRequest;
    private var audioEngine: AVAudioEngine;

    init( audioEngine: AVAudioEngine, onError:ErrorCallback?, onText: onTextCallback?){
        super.init()
        self.audioEngine = audioEngine;
        self.onText = onText;
        self.onError = onError;
        guard let key = ProcessInfo.processInfo.environment["AWS_KEY"] else {
            onError?("AWS_KEY is not set")
            return;
        }
        apiKey = key;
        guard let secret = ProcessInfo.processInfo.environment["AWS_SECRET"] else {
            onError?("AWS_SECRET is not set")
            return;
        }
        apiSecret = secret;
        
        print("AWS_API = " + apiKey)
        print("AWS_SECRET = " + apiSecret)
        audioStream = AudioStream();
        configure();
    
    }
    func configure(){
        audioStream.setup();

        guard let configuration = AWSServiceConfiguration(
            region: .USEast1,
            credentialsProvider:  AWSStaticCredentialsProvider(
                accessKey: apiKey,
                secretKey: apiSecret)
        ) else {
            onError?("Can't get default service configuration")
            return
        }
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        AWSTranscribeStreaming.register(with: configuration, forKey: transcriptKey)
        transcribeStreamingClient = AWSTranscribeStreaming(forKey: transcriptKey)

        request = AWSTranscribeStreamingStartStreamTranscriptionRequest()
        request.languageCode = .enUS // Set the language code
        request.mediaEncoding = .pcm // Set the audio encoding type
        
        let callbackQueue = DispatchQueue(label: "testStreaming")
        transcribeStreamingClient.setDelegate(self, callbackQueue: callbackQueue)
    }
    
    func connectionStatusDidChange(_ connectionStatus: AWSTranscribeStreamingClientConnectionStatus, withError error: Error?) {
        if( error != nil ) {
            onError?( error?.localizedDescription.description ??  "error received" )
        }
        
        if connectionStatus == .connected {
            DispatchQueue.main.async {
                print("AWS Connected")
                
            }
        }
        
        if connectionStatus == .closed && error == nil {
            DispatchQueue.main.async {
                print("AWS Closed")
            }
        }

    }
    
    func didReceiveEvent(_ event: AWSTranscribeStreamingTranscriptResultStream?, decodingError: Error?) {
        if( decodingError != nil ) {
            onError?( decodingError?.localizedDescription.description ??  "error received" )
        }
        
        guard let event = event else {
            onError?("event unexpectedly nil")
            return
        }
        
        guard let transcriptEvent = event.transcriptEvent else {
            onError?("transcriptEvent unexpectedly nil: event may be an error \(event)")
            return
        }

        guard let results = transcriptEvent.transcript?.results else {
            onError?("No results, waiting for next event")
            return
        }

        guard let firstResult = results.first else {
            onError?("firstResult nil--possibly a partial result: \(event)")
            return
        }

        guard let isPartial = firstResult.isPartial as? Bool else {
            onError?("isPartial unexpectedly nil, or cannot cast NSNumber to Bool")
            return
        }

        guard !isPartial else {
            onError?("Partial result received, waiting for next event (results: \(results))")
            return
        }

        print("Received final transcription event (results: \(results))")
        DispatchQueue.main.async {
            self.onText?("\(results)")
        }

    }

    
    func start(){
        /* printing */
        transcribeStreamingClient.startTranscriptionWSS(request)
        // Start the audio engine
        audioEngine.audioInputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { (buffer, time) in
        }


        try! audioEngine.start()

    }
    
    func stop(){
        transcribeStreamingClient.endTranscription()
    }
    
    func feed( audioData: NSData ){
        // Now that the web socket is connected, it is safe to proceed with streaming
        

        let headers = [
            ":content-type": "audio/wav",
            ":message-type": "event",
            ":event-type": "AudioEvent"
        ]
        
        let chunkSize = 4096
        let audioDataSize = audioData.count
        
        var currentStart = 0
        var currentEnd = min(chunkSize, audioDataSize - currentStart)

        while currentStart < audioDataSize {
            let dataChunk = audioData[currentStart ..< currentEnd]
            let data = NSData.init(bytesNoCopy: dataChunk.first, length: dataChunk.count )
            transcribeStreamingClient.send( data, headers: headers)
            currentStart = currentEnd
            currentEnd = min(currentStart + chunkSize, audioDataSize)
        }
        
        print("Sending end frame")
        self.transcribeStreamingClient.sendEndFrame()

        print("Waiting for final transcription event")
        wait(for: [receivedFinalTranscription], timeout: AWSTranscribeStreamingSwiftTests.networkOperationTimeout)
        
        print("Ending transcription")
        transcribeStreamingClient.endTranscription()
        
        print("Waiting for websocket to close")
        wait(for: [webSocketIsClosed], timeout: AWSTranscribeStreamingSwiftTests.networkOperationTimeout)


        
    }
}
