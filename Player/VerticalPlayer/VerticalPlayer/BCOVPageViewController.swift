//
//  BCOVPageViewController.swift
//  VerticalPlayer
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

import UIKit
import BrightcovePlayerSDK


// Sample videos sourced from pexels.com
let kPolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kAccountId = "5434391461001"
let kPlaylistId = "1791438459701684628"


final class BCOVPageViewController: UIPageViewController {

    fileprivate lazy var playbackService: BCOVPlaybackService = {
        let factory = BCOVPlaybackServiceRequestFactory(accountId: kAccountId,
                                                        policyKey: kPolicyKey)
        return .init(requestFactory: factory)
    }()

    fileprivate lazy var videos: [BCOVVideo] = .init()

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
        let configuration = [ kBCOVPlaybackServiceConfigurationKeyAssetID: kPlaylistId]
        playbackService.findPlaylist(withConfiguration: configuration, queryParameters: nil) {
            [self] (playlist: BCOVPlaylist?,
                    json: [AnyHashable:Any]?,
                    error: Error?) in
            guard let playlist,
                  let videos = playlist.videos as? [BCOVVideo] else {
                if let error {
                    print("ViewController - Error retrieving video playlist: \(error.localizedDescription)")
                }

                return
            }

#if targetEnvironment(simulator)
            self.videos = videos.filter({ !$0.usesFairPlay })
#else
            self.videos = videos
#endif

            if let firstVideo = videos.first,
               let videoVC = newVideoViewController() {
                videoVC.video = firstVideo
                setViewControllers([videoVC], direction: .forward, animated: true)
            }

            for video in videos {
                fetchPoster(video: video)
            }
        }
    }

    fileprivate func fetchPoster(video: BCOVVideo) {
        guard let posterURLStr = video.properties[kBCOVVideoPropertyKeyPoster] as? String,
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

        print("using video at index \(previousVideoIndex)")

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

        print("using video at index \(nextVideoIndex)")

        let video = videos[nextVideoIndex]
        videoVC.video = video

        return videoVC
    }
}
