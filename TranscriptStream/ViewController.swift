//
//  ViewController.swift
//  TranscriptStream
//
//  Created by Yuri Fukuda on 5/30/23.
//

import UIKit
import AVFoundation
import AudioToolbox


class ViewController: UIViewController, UIGestureRecognizerDelegate{
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    var touchStartCallback: (() -> Void)?
    var touchEndCallback: (() -> Void)?
    var audioStream: AudioStream!
    var transcribeStreamer: TranscribeStreamer!

    var triggerView: UIView?
    var _recording = false;
    var recording: Bool {
        get {
            return _recording
        }
        set ( newVal ) {
            _recording = newVal
            print( _recording ? "recording" : "paused" )
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.audio,
                                          completionHandler: { (granted: Bool) in
            })
        }
    }
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        initStreamer( onError: { errorMessage in
            print( "Error" + errorMessage )
        }, onText: { message in
            print( "text: " + message )
        });
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupListner(view: imageView, touchStart:touchStart,
            touchEnd:touchEnd)
    }
                       
    func touchStart(){
        recording = true
        startListning();

    }
                       
    func touchEnd(){
        recording = false
        stopListning();
    }


}

