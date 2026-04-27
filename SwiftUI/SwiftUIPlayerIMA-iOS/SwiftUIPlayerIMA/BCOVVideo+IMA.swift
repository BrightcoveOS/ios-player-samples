//
//  BCOVVideo+IMA.swift
//  SwiftUIPlayerIMA
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

import BrightcoveIMA
import CoreMedia

extension BCOVVideo {

    /// Attach a single VMAP ad tag to the video. The IMA plugin reads this from
    /// `kBCOVIMAAdTag` in the video properties when its ads request policy is VMAP-based.
    func withVMAPTag(_ tag: String) -> BCOVVideo {
        update { mutableVideo in
            var properties = mutableVideo.properties
            properties[kBCOVIMAAdTag] = tag
            mutableVideo.properties = properties
        }
    }

    /// Attach pre-roll, mid-roll, and post-roll VAST cuepoints sharing the same ad tag.
    /// The mid-roll position is computed from the video's reported duration.
    func withVASTCuePoints(adTag: String) -> BCOVVideo {
        // 600 is the standard timescale for video — divides cleanly into the
        // common frame rates (24, 25, 30, 60) so cuepoints land on a frame.
        let midpoint: CMTime
        if let durationMs = properties[BCOVVideo.PropertyKeyDuration] as? NSNumber {
            midpoint = CMTimeMakeWithSeconds(durationMs.doubleValue / 2 / 1000, preferredTimescale: 600)
        } else {
            // Fallback for live or unknown-duration assets — fire the
            // mid-roll 30 s in.
            midpoint = CMTime(seconds: 30, preferredTimescale: 600)
        }

        let cueProperties = [kBCOVIMAAdTag: adTag]
        return update { mutableVideo in
            mutableVideo.cuePoints = BCOVCuePointCollection(withArray: [
                BCOVCuePoint.beforeCuePoint(ofType: kBCOVIMACuePointTypeAd, properties: cueProperties),
                BCOVCuePoint(withType: kBCOVIMACuePointTypeAd, position: midpoint, properties: cueProperties),
                BCOVCuePoint.afterCuePoint(ofType: kBCOVIMACuePointTypeAd, properties: cueProperties),
            ])
        }
    }
}
