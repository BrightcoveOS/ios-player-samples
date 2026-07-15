//
//  UISlider+Extensions.swift
//  CustomControls
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import UIKit


extension UISlider {

    var trackBounds: CGRect {
        trackRect(forBounds: bounds)
    }

    var trackFrame: CGRect {
        guard let superview else { return .zero }
        return convert(trackBounds,
                       to: superview)
    }

    var thumbBounds: CGRect {
        thumbRect(forBounds: frame,
                  trackRect: trackBounds,
                  value: value)
    }

    var thumbFrame: CGRect {
        thumbRect(forBounds: bounds,
                  trackRect: trackFrame,
                  value: value)
    }
}
