//
//  BCOVThumbnailManager.swift
//  FlutterPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import CoreMedia
import UIKit


// MARK: -

final class Thumbnail {

    var startTime: CMTime?
    var endTime:  CMTime?
    var url: URL?
}


// MARK: -

final class BCOVThumbnailManager {

    fileprivate(set) lazy var thumbnails: [Thumbnail] = .init()

    init(thumbnailsURL: URL) {
        URLSession.shared.dataTask(with: URLRequest(url: thumbnailsURL)) {
            [self] (data: Data?, response: URLResponse?, error: Error?) in

            if let error {
                print("BCOVThumbnailManager encountered error: \(error.localizedDescription)")
                return
            }

            guard let data,
                  let thumbnailString = String(data: data, encoding: .utf8) else {
                return
            }

            parseThumbnail(with: thumbnailString)
        }.resume()
    }

    func thumbnailAtTime(_ time: CMTime) -> URL? {
        for thumbnail in thumbnails {
            if let startTime = thumbnail.startTime,
               let endTime = thumbnail.endTime,
               startTime <= time && endTime >= time {
                return thumbnail.url
            }
        }

        return nil
    }

    fileprivate func parseThumbnail(with thumbnailString: String) {

        let lines = thumbnailString.components(separatedBy: "\n")
        for line in lines {
            do {
                // This regular expression pattern may need to be adjusted for your
                // subtitle file as the time range pattern may be different
                let regexString = "([0-9]{2}):([0-9]{2}).([0-9]{3}) --> ([0-9]{2}):([0-9]{2}).([0-9]{3})"
                let regex = try NSRegularExpression(pattern: regexString,
                                                    options: .caseInsensitive)
                let matches = regex.matches(in: line,
                                            options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                            range: NSMakeRange(0, line.count))

                if matches.count == 1 {
                    if let result = matches.first {
                        // If you had to adjust the regular expression pattern above
                        // you will need to adjust the startTime and endTime values
                        // based on the additional data available
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
                            break
                        }

                        let startTime = (startTimeMinute * 60.0 * 60.0) + (startTimeSecond * 60) + (startTimeMS / 1000)
                        let endTime = (endTimeMinute * 60.0 * 60.0) + (endTimeSecond * 60) + (endTimeMS / 1000)

                        // Create a new instance and assign the time range
                        let thumbnail = Thumbnail()
                        thumbnail.startTime = CMTimeMake(value: Int64(startTime),
                                                         timescale: 60)
                        thumbnail.endTime = CMTimeMake(value: Int64(endTime),
                                                       timescale: 60)

                        thumbnails.append(thumbnail)
                    }
                }

                if matches.count == 0 && !line.isEmpty {
                    if let currentThumbnail = thumbnails.last {
                        currentThumbnail.url = URL(string: line)
                    }
                }
            } catch {
                print("Error creating regex")
                break
            }
        }
    }
}
