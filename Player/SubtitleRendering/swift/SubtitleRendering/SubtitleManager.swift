//
//  SubtitleManager.swift
//  SubtitleRendering
//
//  Created by Jeremy Blaker on 3/25/21.
//

import UIKit
import CoreMedia

class Subtitle {
    var startTime: CMTime?
    var endTime: CMTime?
    var text: String?
}

class SubtitleManager {
    
    private var subtitleURL: URL
    private var subtitles: [Subtitle]?
    
    init(url: URL) {
        subtitleURL = url
        
        fetchSubtitleData()
    }

    private func fetchSubtitleData() {
        let task = URLSession.shared.dataTask(with: URLRequest(url: subtitleURL)) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            
            if let error = error {
                print("SubtitleManager encountered error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let subtitleString = String(data: data, encoding: .utf8), let strongSelf = self else {
                return
            }
            
            strongSelf.parseSubtitleString(subtitleString)
        }
        
        task.resume()
    }
    
    private func parseSubtitleString(_ subtitleString: String) {
        let lines = subtitleString.components(separatedBy: "\n")
        
        var _subtitles = [Subtitle]()
        
        var currentSubtitle: Subtitle?
        
        for line in lines {
            
            do {
                // This regular expression pattern may need to be adjusted for your
                // subtitle file as the time range pattern may be different
                let regex = try NSRegularExpression(pattern: "([0-9]{2}):([0-9]{2}).([0-9]{3}) --> ([0-9]{2}):([0-9]{2}).([0-9]{3})", options: .caseInsensitive)
                let matches = regex.matches(in: line, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, line.count))
                
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
                        
                        // let startTime = Double((line as NSString).substring(with: range1)) * 60 * 60
                        
                        guard let startTimeMinute = Double((line as NSString).substring(with: startTimeMinuteRange)), let startTimeSecond = Double((line as NSString).substring(with: startTimeSecondRange)), let startTimeMS = Double((line as NSString).substring(with: startTimeMSRange)), let endTimeMinute = Double((line as NSString).substring(with: endTimeMinuteRange)), let endTimeSecond = Double((line as NSString).substring(with: endTimeSecondRange)), let endTimeMS = Double((line as NSString).substring(with: endTimeMSRange)) else {
                            break;
                        }
                        
                        let startTime = (startTimeMinute * 60.0 * 60.0) + (startTimeSecond * 60) + (startTimeMS / 1000)
                        
                        let endTime = (endTimeMinute * 60.0 * 60.0) + (endTimeSecond * 60) + (endTimeMS / 1000)
                        
                        // Add previous subtitle to array, if we have one
                        if let currentSubtitle = currentSubtitle {
                            _subtitles.append(currentSubtitle)
                        }
                        
                        // Create a new instance and assign the time range
                        let _currentSubtitle = Subtitle()
                        _currentSubtitle.startTime = CMTimeMake(value: Int64(startTime), timescale: 60)
                        _currentSubtitle.endTime = CMTimeMake(value: Int64(endTime), timescale: 60)
                        
                        currentSubtitle = _currentSubtitle
                    }
                }
                
                if matches.count == 0 && line.count > 0 {
                    if let currentSubtitle = currentSubtitle {
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
        
        subtitles = _subtitles
    }
    
    func subtitleForTime(_ time: CMTime) -> String? {
        guard let subtitles = subtitles else {
            return nil
        }
        
        for subtitle in subtitles {
            if let startTime = subtitle.startTime, let endTime = subtitle.endTime {
                if startTime <= time && endTime >= time
                {
                    return subtitle.text ?? nil;
                }
            }
        }
        
        return nil
    }
    
}
