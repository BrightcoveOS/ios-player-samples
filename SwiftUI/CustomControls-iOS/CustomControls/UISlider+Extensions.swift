//
//  UISlider+Extensions.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit


extension UISlider {

    var trackBounds: CGRect {
        return trackRect(forBounds: bounds)
    }

    var trackFrame: CGRect {
        guard let superview else { return .zero }
        return convert(trackBounds,
                       to: superview)
    }

    var thumbBounds: CGRect {
        return thumbRect(forBounds: frame,
                         trackRect: trackBounds,
                         value: value)
    }

    var thumbFrame: CGRect {
        return thumbRect(forBounds: bounds,
                         trackRect: trackFrame,
                         value: value)
    }
}
