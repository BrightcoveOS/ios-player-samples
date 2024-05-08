//
//  ThumbnailManager.swift
//  CustomControls
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import Combine
import CoreMedia
import UIKit


enum ThumbnailError: Error {
    case fetchError
    case decodeError
    case urlNotFound
}


final class ThumbnailManager {

    fileprivate var cancellables = [AnyCancellable]()
    fileprivate let cache = NSCache<NSString, UIImage>()

    fileprivate lazy var thumbnails: [ThumbnailModel] = .init()
    fileprivate lazy var session: URLSession = URLSession(configuration: .default)

    init(url: URL) {
        fetchThumbnailData(url: url)
    }

    func thumbnailAtTime(_ time: CMTime) -> UIImage? {
        for thumbnail in thumbnails {
            if let startTime = thumbnail.startTime,
               let endTime = thumbnail.endTime,
               startTime...endTime ~= time,
               let thumbnailCachePath = thumbnail.url?.absoluteString {
                return get(forKey: thumbnailCachePath)
            }
        }

        return nil
    }

    func loadAndCacheThumbnail(_ urlCachePath: String) -> AnyPublisher<UIImage, ThumbnailError> {
        Future<UIImage, ThumbnailError> { [self] promise in
            if let cachedImage = get(forKey: urlCachePath) {
                promise(.success(cachedImage))
                return
            }

            guard let url = URL(string: urlCachePath) else {
                promise(.failure(.urlNotFound))
                return
            }

            session.dataTask(with: url) { data, response, error in
                guard let data,
                      error == nil else { return }

                DispatchQueue.main.async { [self] in
                    guard let image = UIImage(data: data) else {
                        promise(.failure(.decodeError))
                        return
                    }

                    set(image, forKey: urlCachePath)
                    promise(.success(image))
                }
            }.resume()
        }
        .eraseToAnyPublisher()
    }
}


extension ThumbnailManager {

    func get(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    fileprivate func set(_ image: UIImage,
                         forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}


fileprivate extension ThumbnailManager {

    func fetchThumbnailData(url: URL) {
        session.dataTask(with: URLRequest(url: url)) {
            data, response, error in
            if let error {
                print("Fetch Thumbnail Error With Description: \(error.localizedDescription)")
                return
            }

            guard let data,
                  let thumbnailData = String(data: data, encoding: .utf8) else {
                return
            }

            DispatchQueue.main.async { [self] in
                parseThumbnail(thumbnailData)
            }
        }.resume()
    }

    func parseThumbnail(_ thumbnail: String) {
        thumbnails = .init()

        let lines = thumbnail.components(separatedBy: "\n").filter { !$0.isEmpty }
        for line in lines {
            do {
                let regex = try NSRegularExpression(pattern: "([0-9]{2}):([0-9]{2}).([0-9]{3}) --> ([0-9]{2}):([0-9]{2}).([0-9]{3})",
                                                    options: .caseInsensitive)
                let matches = regex.matches(in: line,
                                            options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                            range: NSMakeRange(0, line.count))
                if matches.count == 1 {
                    if let result = matches.first {
                        let startTimeMinuteRange = result.range(at: 1)
                        let startTimeSecondRange = result.range(at: 2)
                        let startTimeMSRange = result.range(at: 3)
                        let endTimeMinuteRange = result.range(at: 4)
                        let endTimeSecondRange = result.range(at: 5)
                        let endTimeMSRange = result.range(at: 6)
                        guard let startTimeMinute = Double((line as NSString).substring(with: startTimeMinuteRange)),
                              let startTimeSecond = Double((line as NSString).substring(with: startTimeSecondRange)),
                              let startTimeMS = Double((line as NSString).substring(with: startTimeMSRange)),
                              let endTimeMinute = Double((line as NSString).substring(with: endTimeMinuteRange)),
                              let endTimeSecond = Double((line as NSString).substring(with: endTimeSecondRange)),
                              let endTimeMS = Double((line as NSString).substring(with: endTimeMSRange)) else {
                            break;
                        }

                        let startTime = (startTimeMinute * 60.0 * 60.0) + (startTimeSecond * 60) + (startTimeMS / 1000)

                        let endTime = (endTimeMinute * 60.0 * 60.0) + (endTimeSecond * 60) + (endTimeMS / 1000)

                        // Create a new instance and assign the time range
                        let thumbnail = ThumbnailModel()

                        thumbnail.startTime = CMTimeMake(value: Int64(startTime), timescale: 60)
                        thumbnail.endTime = CMTimeMake(value: Int64(endTime), timescale: 60)

                        thumbnails.append(thumbnail)
                    }
                }

                if matches.count == 0 && line.count > 0 {
                    if let currentThumbnail = thumbnails.last {
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
                    }
                }
            } catch {
                print("Error creating regex")
                break
            }
        }
    }
}
