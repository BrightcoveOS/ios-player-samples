//
//  ViewController.swift
//  SubtitleRendering
//
//  Created by Jeremy Blaker on 3/25/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var subtitlesLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var subtitlesBottomConstraint: UIView!

}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextTrackCell")!
        
        return cell
    }
    
}
