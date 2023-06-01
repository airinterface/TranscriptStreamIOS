//
//  ViewController.swift
//  TranscriptStream
//
//  Created by Yuri Fukuda on 5/30/23.
//

import UIKit

class ViewController: UIViewController, UIGestureRecognizerDelegate{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    var touchStartCallback: (() -> Void)?
    var touchEndCallback: (() -> Void)?
    var triggerView: UIView?
    var _recording = false;
    var recording: Bool {
        get {
            return _recording
        }
        set ( newVal ) {
            _recording = newVal
        }
    }

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupListner(view: imageView, touchStart:touchStart,
            touchEnd:touchEnd)
    }
                       
    func touchStart(){
        recording = true

    }
                       
    func touchEnd(){
        recording = false
    }


}

