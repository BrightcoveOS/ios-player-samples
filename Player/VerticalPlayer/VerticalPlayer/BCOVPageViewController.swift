//
//  BCOVPageViewController.swift
//  VerticalPlayer
//
//  Copyright © 2026 Brightcove, Inc. All rights reserved.
//

/*
 * This sample app shows how to build a vertical, full-screen paging video
 * feed (in the style of TikTok or Reels) from a Video Cloud playlist.
 *
 * A `UIPageViewController` provides swipe paging and wraps around from the
 * last video back to the first. Each page is a `VideoViewController` running
 * its own `BCOVPlaybackController`, and each session uses a `.resizeAspectFill`
 * video gravity so the video fills the screen.
 *
 * `-requestContentFromPlaybackService` loads the playlist and prefetches every
 * video's poster image so it is cached before its page appears.
 */

import UIKit
import BrightcovePlayerSDK


// Sample videos sourced from pexels.com
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kAccountId = "5434391461001"
let kPlaylistId = "1791438459701684628"


final class BCOVPageViewController: UIPageViewController {

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(withAccountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(withRequestFactory: factory)
    }()

    fileprivate var videos: [BCOVVideo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self

        requestContentFromPlaybackService()
    }

    fileprivate func newVideoViewController() -> VideoViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "VideoViewController") as? VideoViewController
    }

    fileprivate func requestContentFromPlaybackService() {
        let configuration = [ BCOVPlaybackService.ConfigurationKeyAssetID: kPlaylistId]
        playbackService.findPlaylist(withConfiguration: configuration, queryParameters: nil) {
            [weak self] (playlist: BCOVPlaylist?,
                         json: Any?,
                         error: Error?) in
            guard let self,
                  let playlist else {
                if let error {
                    print("BCOVPageViewController - Error retrieving video playlist: \(error.localizedDescription)")
                }

                return
            }

            let videos = playlist.videos

#if targetEnvironment(simulator)
            self.videos = videos.filter({ !$0.usesFairPlay })
#else
            self.videos = videos
#endif

            if let firstVideo = self.videos.first,
               let videoVC = newVideoViewController() {
                videoVC.video = firstVideo
                setViewControllers([videoVC], direction: .forward, animated: true)
            }

            for video in self.videos {
                fetchPoster(video: video)
            }
        }
    }

    fileprivate func fetchPoster(video: BCOVVideo) {
        guard let posterURLStr = video.properties[BCOVVideo.PropertyKeyPoster] as? String,
              let posterURL = URL(string: posterURLStr) else {
            return
        }
        let urlRequest = URLRequest(url: posterURL)
        URLSession.shared.dataTask(with: urlRequest) {
            (data: Data?, response: URLResponse?, error: Error?) in
            if let error {
                print(error.localizedDescription)
                return
            }
        }.resume()
    }
}


// MARK: - UIPageViewControllerDataSource

extension BCOVPageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVideoVC = viewController as? VideoViewController,
              let currentVideo = currentVideoVC.video,
              let videoVC = newVideoViewController(),
              let currentVideoIndex = videos.firstIndex(of: currentVideo) else {
            return nil
        }

        var previousVideoIndex = -1

        if currentVideoIndex == 0 {
            previousVideoIndex = videos.count - 1
        } else {
            previousVideoIndex = currentVideoIndex - 1
        }

        let video = videos[previousVideoIndex]
        videoVC.video = video

        return videoVC
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVideoVC = viewController as? VideoViewController,
              let currentVideo = currentVideoVC.video,
              let videoVC = newVideoViewController(),
              let currentVideoIndex = videos.firstIndex(of: currentVideo) else {
            return nil
        }

        var nextVideoIndex = -1

        if currentVideoIndex >= (videos.count - 1) {
            nextVideoIndex = 0
        } else {
            nextVideoIndex = currentVideoIndex + 1
        }

        let video = videos[nextVideoIndex]
        videoVC.video = video

        return videoVC
    }
}
