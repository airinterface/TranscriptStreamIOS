//
//  AVAudioPCMBuffer+Converter.swift
//  TranscriptStream
//
//  Created by Yuri Fukuda on 6/7/23.
//

import Foundation
import AVFAudio

extension AVAudioPCMBuffer {
    func data()-> Data? {
        let channelCount = 1 // Given PCMBuffer channel count is 1
        let channels = UnsafeBufferPointer(start: int16ChannelData, count: channelCount)
        let ch0Data = NSData(bytes: channels[0], length: Int(frameCapacity * format.streamDescription.pointee.mBytesPerFrame)) as Data
        return ch0Data
    }
}
