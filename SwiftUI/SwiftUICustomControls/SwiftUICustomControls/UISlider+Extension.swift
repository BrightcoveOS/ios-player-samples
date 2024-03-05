//
//  UISlider+Extension.swift
//  SwiftUICustomControls
//
//  Created by iletai on 05/03/2024.
//

import Foundation
import UIKit

// MARK: - UISlider Extension
extension UISlider {
    var trackBounds: CGRect {
        return trackRect(forBounds: bounds)
    }

    var trackFrame: CGRect {
        guard let superView = superview else { return CGRect.zero }
        return self.convert(trackBounds, to: superView)
    }

    var thumbBounds: CGRect {
        return thumbRect(forBounds: frame, trackRect: trackBounds, value: value)
    }

    var thumbFrame: CGRect {
        return thumbRect(forBounds: bounds, trackRect: trackFrame, value: value)
    }
}
