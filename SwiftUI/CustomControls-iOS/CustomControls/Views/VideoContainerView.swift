//
//  VideoContainerView.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import SwiftUI


struct VideoContainerView: UIViewRepresentable {
    typealias UIViewType = UIView

    let view: UIView?

    func makeUIView(context: Context) -> UIView {
        return view ?? UIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


// MARK: -

#if DEBUG
struct VideoContainerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoContainerView(view: UIView(frame: .zero))
            .background(Color.secondary)
    }
}
#endif
