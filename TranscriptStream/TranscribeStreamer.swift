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
typealias onPartialTextCallback = ( String)-> Void;





class TranscribeStreamer:NSObject, AWSTranscribeStreamingClientDelegate {
    
    private let transcriptKey = "transcribeStreaming"
    private var apiKey:String!;
    private var apiSecret:String!;
    let timeoutIntervalSeconds = Double(10)
    private var closeRequeseted = false;
    private let timeoutQueue = DispatchQueue(label: "io.airinterface.timeout")

    private var onError:ErrorCallback?;
    private var onText:onTextCallback?;
    private var onPartialText: onPartialTextCallback?;

    private var transcribeStreamingClient: AWSTranscribeStreaming!;
    private var request: AWSTranscribeStreamingStartStreamTranscriptionRequest!;
    private var started = false;
    private var sessionEstablished = false;
    init( onError:ErrorCallback?, onText: onTextCallback?, onPartial: onPartialTextCallback? ){
        super.init()
        self.onText = onText;
        self.onPartialText = onPartial;
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
            DispatchQueue.main.async {
                print("Received partial transcription event (results: \(results))")
                if( results.last?.alternatives?.count ?? 0 > 0 ){
                    print("Received partial transcription event (results: \(results))")
                }
                let partialTranscripts = results.last?.alternatives?.last?.transcript ?? ""
                print("(P:\(partialTranscripts))")
                self.onPartialText?( partialTranscripts )
            }
            return
        }
        
        DispatchQueue.main.async {
            let text = results.last?.alternatives?.last?.transcript ?? ""
            self.onText?( text )
        }

        print("Received final transcription event (results: \(results))")
        self.closeConnectionIfRequested();

    }

    
    let timeoutWorkItem = DispatchWorkItem {
        // Handle the timeout scenario here
        print("Request timed out")
    }

    func closeConnectionIfRequested(){
        if( closeRequeseted ){
            closeRequeseted = false;
            stop()
        }
    }
    
    func waitAndCloseConnection(){
        closeRequeseted = true;
        timeoutQueue.asyncAfter(deadline: .now() + timeoutIntervalSeconds, execute: closeConnectionIfRequested )
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
            waitAndCloseConnection()
        }

    }
    
    func initialzeConnection(){
        print("Socket Requested Starting Transcription")
        transcribeStreamingClient.startTranscriptionWSS(request)
    }

    func stop(){
        started = false;
        sessionEstablished = false;
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

        
    }
}
