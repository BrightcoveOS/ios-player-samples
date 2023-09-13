//
//  VideoView.swift
//  SwiftUICustomControls
//
//  Copyright © 2023 Brightcove, Inc. All rights reserved.
//

import SwiftUI

struct VideoView: UIViewRepresentable {
    typealias UIViewType = UIView

    let view: UIView?

    func makeUIView(context: Context) -> UIView {
        return view ?? UIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


// MARK: -

#if DEBUG
struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(view: UIView(frame: .zero))
            .background(Color.secondary)
    }
}
#endif
