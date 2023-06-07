//
//  VieController+AudioControl.swift
//  TranscriptStream
//
//  Created by Yuri Fukuda on 6/2/23.
//

import Foundation


extension ViewController {
    
    func initStreamer( onError: @escaping (String)-> Void, onText:@escaping (String)-> Void){
        audioStream = AudioStream();
        audioStream.setup()
        transcribeStreamer = TranscribeStreamer( onError: onError,
                                                 onText: onText )
        transcribeStreamer.start()
    }

    func startListning(){
        
        audioStream.start( { data  in
            self.transcribeStreamer.feed( data )
        });
    }

    func stopListning(){
        audioStream.stop()
        transcribeStreamer.pause()
    }

}
