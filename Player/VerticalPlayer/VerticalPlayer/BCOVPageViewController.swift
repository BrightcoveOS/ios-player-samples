//
//  BCOVPageViewController.swift
//  VerticalPlayer
//
//  Created by Jeremy Blaker on 9/28/23.
//

import UIKit
import BrightcovePlayerSDK

// Sample videos sourced from pexels.com

let kViewControllerPlaybackServicePolicyKey = "BCpkADawqM0T8lW3nMChuAbrcunBBHmh4YkNl5e6ZrKQwPiK_Y83RAOF4DP5tyBF_ONBVgrEjqW6fbV0nKRuHvjRU3E8jdT9WMTOXfJODoPML6NUDCYTwTHxtNlr5YdyGYaCPLhMUZ3Xu61L"
let kViewControllerAccountID = "5434391461001"
let kViewControllerPlaylistID = "1791438459701684628"

class BCOVPageViewController: UIPageViewController {

    var playlist: BCOVPlaylist?
    
    var videoViewController1: VideoViewController?
    var videoViewController2: VideoViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        requestContentFromPlaybackService()
    }
    
    func newVideoViewController() -> VideoViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "VideoViewController") as? VideoViewController
    }
    
    func requestContentFromPlaybackService() {
        let playbackService = BCOVPlaybackService(accountId: kViewControllerAccountID, policyKey: kViewControllerPlaybackServicePolicyKey)
        let configuration = [kBCOVPlaybackServiceConfigurationKeyAssetID:kViewControllerPlaylistID]
        playbackService?.findPlaylist(withConfiguration: configuration, queryParameters: nil, completion: { [weak self] (playlist: BCOVPlaylist?, json: [AnyHashable:Any]?, error: Error?) in
            if let error = error {
                print("ViewController Debug - Error retrieving playlist: \(error.localizedDescription)")
                return
            }

            guard let playlist = playlist else {
                return
            }

            self?.playlist = playlist
            if let firstVideo = self?.playlist?.videos.first as? BCOVVideo, let videoVC = self?.newVideoViewController() {
                videoVC.video = firstVideo
                self?.setViewControllers([videoVC], direction: .forward, animated: true)
            }

            for video in playlist.videos {
                if let video = video as? BCOVVideo {
                    self?.fetchPoster(video: video)
                }
            }
        })
    }

    func fetchPoster(video: BCOVVideo) {
        guard let posterURLStr = video.properties[kBCOVVideoPropertyKeyPoster] as? String, let posterURL = URL(string: posterURLStr) else {
            return
        }
        let urlRequest = URLRequest(url: posterURL)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
        task.resume()
    }
}

extension BCOVPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVideoVC = viewController as? VideoViewController, let currentVideo = currentVideoVC.video, let videoVC = newVideoViewController(), let playlist = playlist, let videos = playlist.videos as? [BCOVVideo] else {
            return nil
        }
        
        guard let currentVideoIndex = videos.firstIndex(of: currentVideo) else {
            return nil
        }
        
        var previousVideoIndex = -1
        
        if currentVideoIndex == 0 {
            previousVideoIndex = videos.count - 1
        } else {
            previousVideoIndex = currentVideoIndex - 1
        }

        guard let video = playlist.videos[previousVideoIndex] as? BCOVVideo else {
            return nil
        }
        
        print("using video at index \(previousVideoIndex)")

        videoVC.video = video

        return videoVC
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVideoVC = viewController as? VideoViewController, let currentVideo = currentVideoVC.video, let videoVC = newVideoViewController(), let playlist = playlist, let videos = playlist.videos as? [BCOVVideo] else {
            return nil
        }

        guard let currentVideoIndex = videos.firstIndex(of: currentVideo) else {
            return nil
        }
        
        var nextVideoIndex = -1
        
        if currentVideoIndex >= (videos.count - 1) {
            nextVideoIndex = 0
        } else {
            nextVideoIndex = currentVideoIndex + 1
        }

        guard let video = playlist.videos[nextVideoIndex] as? BCOVVideo else {
            return nil
        }
        
        print("using video at index \(nextVideoIndex)")

        videoVC.video = video

        return videoVC
    }
    
}
