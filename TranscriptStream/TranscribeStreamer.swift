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




class TranscribeStreamer:NSObject, AWSTranscribeStreamingClientDelegate {
    
    private let transcriptKey = "transcribeStreaming"
    private var apiKey:String!;
    private var apiSecret:String!;
    private var onError:ErrorCallback?;
    private var onText:onTextCallback?;
    private var transcribeStreamingClient: AWSTranscribeStreaming!;
    private var request: AWSTranscribeStreamingStartStreamTranscriptionRequest!;
    private var started = false;
    private var sessionEstablished = false;
    init( onError:ErrorCallback?, onText: onTextCallback?){
        super.init()
        self.onText = onText;
        self.onError = onError;
        guard let key = AWS_KEY else {
            onError?("AWS_KEY is not set")
            return;
        }
        apiKey = key;
        guard let secret = AWS_SECRET else {
            onError?("AWS_SECRET is not set")
            return;
        }
        apiSecret = secret;
        print("AWS_API = " + apiKey)
        print("AWS_SECRET = " + apiSecret)
        configure();
    
    }
    func configure(){
                
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
        request.mediaSampleRateHertz = 16000
        

        
        let callbackQueue = DispatchQueue(label: "testStreaming")
        transcribeStreamingClient.setDelegate(self, callbackQueue: DispatchQueue.global())
    }
    
    func connectionStatusDidChange(_ connectionStatus: AWSTranscribeStreamingClientConnectionStatus, withError error: Error?) {
        if( error != nil ) {
            onError?( error?.localizedDescription.description ??  "error received" )
        }
        
        if connectionStatus == .connected {
            sessionEstablished = true
            DispatchQueue.main.async {
                print("AWS Connected")
                
            }
        }
        
        if connectionStatus == .closed && error == nil {
            sessionEstablished = false
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
        print("Starting Transcription")
        // Start the audio engine
    }
    
    func pause(){
        if( started ) {
            print("pausing frame")
            self.transcribeStreamingClient.sendEndFrame()
            started = false
        }

    }
    
    func initialzeConnection(){
        print("Socket Requested Starting Transcription")
        transcribeStreamingClient.startTranscriptionWSS(request)
    }

    func stop(){
        started = false;
        transcribeStreamingClient.endTranscription()
    }
    
    func feed( _ audioData: NSData ){
        if( audioData.isEmpty ) {
            print("audio is empty")
            return;
        }
        
        // Now that the web socket is connected, it is safe to proceed with streaming
        if( !started ) {
            initialzeConnection()
            started = true;
        }
        if( !sessionEstablished ) {
            print("session isn't established")
            return;
        }
        print("Sending");

        let headers = [
            ":content-type": "audio/wav",
            ":message-type": "event",
            ":event-type": "AudioEvent"
        ]
        
        transcribeStreamingClient.send( Data( audioData ), headers: headers)

//        print("Waiting for final transcription event")
//        wait(for: [receivedFinalTranscription], timeout: AWSTranscribeStreamingSwiftTests.networkOperationTimeout)
//
//        print("Ending transcription")
//        transcribeStreamingClient.endTranscription()
//
//        print("Waiting for websocket to close")
//        wait(for: [webSocketIsClosed], timeout: AWSTranscribeStreamingSwiftTests.networkOperationTimeout)


        
    }
}
