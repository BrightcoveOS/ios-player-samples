//
//  ImageLoader.swift
//  SwiftUIPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Foundation


final class ImageLoader: ObservableObject {

    @Published
    var data = Data()

    init(urlString: String) {

        guard let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) {
            data, response, error in

            guard let data else { return }

            DispatchQueue.main.async { [weak self] in
                self?.data = data
            }
        }

        task.resume()
    }
}
