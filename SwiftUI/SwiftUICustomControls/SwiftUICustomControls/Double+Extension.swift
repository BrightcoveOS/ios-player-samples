//
//  Double+Extension.swift
//  SwiftUICustomControls
//
//  Created by Lê Quang Trọng Tài on 3/3/24.
//

import Foundation
import CoreMedia

// MARK: - Double Extension
extension Double {
    var asCMTime: CMTime {
        CMTime(seconds: self, preferredTimescale: CMTimeScale(60))
    }
}
