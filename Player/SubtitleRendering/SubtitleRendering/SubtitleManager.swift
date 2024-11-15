//
//  SubtitleManager.swift
//  SubtitleRendering
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import CoreMedia


final class Subtitle {
    var startTime: CMTime?
    var endTime: CMTime?
    var text: String?
}


final class SubtitleManager {

    fileprivate lazy var subtitles: [Subtitle] = .init()

    init(subtitleURL: URL) {
        URLSession.shared.dataTask(with: URLRequest(url: subtitleURL)) {
            [self] (data: Data?, response: URLResponse?, error: Error?) in

            if let error {
                print("SubtitleManager encountered error: \(error.localizedDescription)")
                return
            }

            guard let data,
                  let subtitleString = String(data: data, encoding: .utf8) else {
                return
            }

            parseSubtitle(with: subtitleString)
        }.resume()
    }

    fileprivate func parseSubtitle(with subtitleString: String) {
        subtitles = .init()

        let lines = subtitleString.components(separatedBy: "\n")
        for line in lines {
            do {
                // This regular expression pattern may need to be adjusted for your
                // subtitle file as the time range pattern may be different
                let regex = try NSRegularExpression(pattern: "([0-9]{2}):([0-9]{2}).([0-9]{3}) --> ([0-9]{2}):([0-9]{2}).([0-9]{3})",
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
                        let subtitle = Subtitle()
                        subtitle.startTime = CMTimeMake(value: Int64(startTime),
                                                                timescale: 60)
                        subtitle.endTime = CMTimeMake(value: Int64(endTime),
                                                              timescale: 60)

                        subtitles.append(subtitle)
                    }
                }

                if matches.count == 0 && !line.isEmpty {
                    if let currentSubtitle = subtitles.last {
                        if let text = currentSubtitle.text {
                            currentSubtitle.text = text.appending(" \(line)")
                        } else {
                            currentSubtitle.text = line
                        }
                    }
                }
            } catch {
                print("Error creating regex")
                break
            }
        }
    }

    func subtitleForTime(_ time: CMTime) -> String? {
        for subtitle in subtitles {
            if let startTime = subtitle.startTime,
               let endTime = subtitle.endTime {
                if startTime <= time && endTime >= time {
                    return subtitle.text
                }
            }
        }

        return nil
    }
}
