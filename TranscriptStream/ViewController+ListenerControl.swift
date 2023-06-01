//
//  ListenerControl.swift
//  TranscriptStream
//
//  Created by Yuri Fukuda on 5/31/23.
//

import Foundation
import UIKit


extension ViewController {
    
    func setupListner( view: UIView, touchStart: (() -> Void)?, touchEnd: (() -> Void)?  ){
        self.triggerView = view;
        self.touchStartCallback = touchStart;
        self.touchEndCallback = touchEnd;
        self.setupGestureRecognizers();
        
    }
        
    private func setupGestureRecognizers() {
        self.triggerView!.isUserInteractionEnabled = true
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        tapGesture.minimumPressDuration = 0.0

        self.triggerView!.addGestureRecognizer(tapGesture)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Perform custom logic to determine if the gesture recognizer should recognize the touch or not
        return true
    }

    
    @IBAction private func handleTap(_ gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .began:
            touchStartCallback?()
            break;
        case .ended:
            let touchPoint = gesture.location(in: view)
            if view.bounds.contains(touchPoint) {
                touchEndCallback?()
            }
            break;
        default:
            break
        }
    }

    
}
