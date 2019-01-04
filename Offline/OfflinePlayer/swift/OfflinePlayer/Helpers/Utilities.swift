//
//  Utilities.swift
//  OfflinePlayer
//
//  Copyright © 2019 Brightcove, Inc. All rights reserved.
//

import UIKit

class Utilities: NSObject {
    
    class func directorySize(folderPath: String) -> Double {
        
        var _directorySize: Double = 0
        do {
            let filesArray = try FileManager.default.subpathsOfDirectory(atPath: folderPath)
            
            for fileName in filesArray {
                let path = folderPath + "/" + fileName
                let fileDictionary = try FileManager.default.attributesOfItem(atPath: path)
                guard let filesize = fileDictionary[FileAttributeKey.size] as? Double else {
                    return 0
                }
                _directorySize = _directorySize + filesize
            }
        } catch let error {
            print("\(error.localizedDescription)")
        }
        
        return _directorySize
        
    }

}
