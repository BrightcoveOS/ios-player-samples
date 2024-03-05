//
//  ThumbnailManager.swift
//  SwiftUICustomControls
//
//  Created by iletai on 28/02/2024.
//

import Foundation
import UIKit
import CoreMedia
import Combine

final class ThumbnailManager {
    private var cancellables = [AnyCancellable]()
    private var thumbnails: [ThumbnailModel]?
    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession

    init(url: URL) {
        self.session = URLSession(configuration: .default)
        fetchThumbnailData(url: url)
    }
    
    /// Get Thumbnail Video View
    /// - Parameter time: At Current Time
    /// - Returns: UIImage?
    func thumbnailAtTime(_ time: CMTime) -> UIImage? {
        guard let thumbnails = thumbnails else {
            return nil
        }
        for thumbnail in thumbnails {
            if let startTime = thumbnail.startTime,
                let endTime = thumbnail.endTime {
                if startTime...endTime ~= time {
                    if let thumbnailCachePath = thumbnail.url?.absoluteString {
                        return get(forKey: thumbnailCachePath)
                    }
                }
            }
        }
        return nil
    }
    
    /// Combine Load And Save Image To NSCache
    /// - Parameter urlCache: URL Path Cache
    /// - Returns: AnyPublisher<UIImage, Error>
    func loadAndCacheThumbnail(_ urlCachePath: String) -> AnyPublisher<UIImage, Error> {
        Future<UIImage, Error> { [weak self] promise in
            guard let self else {
                promise(.failure(ThumbnailError.fetchError))
                return
            }
            if let cachedImage = get(forKey: urlCachePath) {
                promise(.success(cachedImage))
                return
            }

            guard let url = URL(string: urlCachePath) else {
                promise(.failure(ThumbnailError.urlNotFound))
                return
            }

            let task = session.dataTask(with: url) { data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.global().async {
                    guard let image = UIImage(data: data) else {
                        promise(.failure(ThumbnailError.decodeError))
                        return
                    }
                    self.set(image, forKey: urlCachePath)
                    promise(.success(image))
                }
            }
            task.resume()
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private Function
private extension ThumbnailManager {
    func fetchThumbnailData(url: URL) {
        let task = session.dataTask(
            with: URLRequest(url: url)
        ) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                print("Fetch Thumbnail Error With Description: \(error.localizedDescription)")
                return
            }
            guard let data = data,
                    let thumbnailData = String(data: data, encoding: .utf8) else {
                return
            }
            DispatchQueue.global().async {
                self.parseThumbnail(thumbnailData)
            }
        }
        task.resume()
    }

    func parseThumbnail(_ thumbnail: String) {
        let lines =  thumbnail.components(separatedBy: "\n").filter { !$0.isEmpty }
        var _thumbnails = [ThumbnailModel]()
        var currentThumbnail: ThumbnailModel?
        for line in lines {
            do {
                let regex = try NSRegularExpression(pattern: "([0-9]{2}):([0-9]{2}).([0-9]{3}) --> ([0-9]{2}):([0-9]{2}).([0-9]{3})", options: .caseInsensitive)
                let matches = regex.matches(in: line, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, line.count))
                if matches.count == 1 {
                    if let result = matches.first {
                        let startTimeMinuteRange = result.range(at: 1)
                        let startTimeSecondRange = result.range(at: 2)
                        let startTimeMSRange = result.range(at: 3)
                        let endTimeMinuteRange = result.range(at: 4)
                        let endTimeSecondRange = result.range(at: 5)
                        let endTimeMSRange = result.range(at: 6)
                        guard let startTimeMinute = Double((line as NSString).substring(with: startTimeMinuteRange)), let startTimeSecond = Double((line as NSString).substring(with: startTimeSecondRange)), let startTimeMS = Double((line as NSString).substring(with: startTimeMSRange)), let endTimeMinute = Double((line as NSString).substring(with: endTimeMinuteRange)), let endTimeSecond = Double((line as NSString).substring(with: endTimeSecondRange)), let endTimeMS = Double((line as NSString).substring(with: endTimeMSRange)) else {
                            break;
                        }

                        let startTime = (startTimeMinute * 60.0 * 60.0) + (startTimeSecond * 60) + (startTimeMS / 1000)

                        let endTime = (endTimeMinute * 60.0 * 60.0) + (endTimeSecond * 60) + (endTimeMS / 1000)

                        if let currentThumbnail = currentThumbnail {
                            _thumbnails.append(currentThumbnail)
                        }

                        // Create a new instance and assign the time range
                        let _currentThumbnail = ThumbnailModel()
                        _currentThumbnail.startTime = CMTimeMake(value: Int64(startTime), timescale: 60)
                        _currentThumbnail.endTime = CMTimeMake(value: Int64(endTime), timescale: 60)
                        currentThumbnail = _currentThumbnail
                    }
                }

                if matches.count == 0 && line.count > 0 {
                    if let currentThumbnail = currentThumbnail {
                        guard let urlParse = URL(string: line) else {
                            break
                        }
                        currentThumbnail.url = urlParse
                        loadAndCacheThumbnail(urlParse.absoluteString)
                            .receive(on: RunLoop.main)
                            .sink(receiveCompletion: { completion in
                                switch completion {
                                case .finished:
                                    break
                                case .failure(let failure):
                                    print("Cache Video Thumbnail Error: \(failure.localizedDescription)")
                                }
                            }, receiveValue: { _ in
                            })
                            .store(in: &cancellables)
                        if let lastItem = lines.last, !lastItem.isEmpty, lastItem == line {
                            _thumbnails.append(currentThumbnail)
                        }
                    }
                }

            } catch {
                print("Error creating regex")
                break
            }

        }
        thumbnails = _thumbnails
    }
}

// MARK: - Cache Set/Get
extension ThumbnailManager {
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    func get(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
}

enum ThumbnailError: Error {
    case fetchError
    case decodeError
    case urlNotFound
}
