//
//  Logging.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import OSLog

/// Unified Logging subsystem for this sample. Stream from the command line:
///
///     log stream --predicate 'subsystem == "com.brightcove.SwiftUIPlayerIMA"' --info
///
/// Filter by category (e.g. only ads):
///
///     log stream --predicate 'subsystem == "com.brightcove.SwiftUIPlayerIMA" AND category == "ads"' --info
enum Log {
    private static let subsystem = "com.brightcove.SwiftUIPlayerIMA"

    static let session = Logger(subsystem: subsystem, category: "session")
    static let playback = Logger(subsystem: subsystem, category: "playback")
    static let ads = Logger(subsystem: subsystem, category: "ads")
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
}
