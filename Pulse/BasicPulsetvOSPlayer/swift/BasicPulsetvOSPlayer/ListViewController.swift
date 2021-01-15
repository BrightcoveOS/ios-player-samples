//
//  ListViewController.swift
//  BasicPulsetvOSPlayer
//
//  Created by Carlos Ceja on 3/13/20.
//  Copyright © 2020 Brightcove. All rights reserved.
//

import AppTrackingTransparency
import UIKit

class ListViewController: UIViewController
{
    
    @IBOutlet private weak var tableView: UITableView!
    lazy fileprivate var videoItems: [BCOVPulseVideoItem] = {
        
        var _videoItems = [BCOVPulseVideoItem]()
        
        if let path = Bundle.main.path(forResource: "Library", ofType: "json")
        {
            do
            {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? [Dictionary<String, AnyObject>]
                {
                    for item in jsonResult
                    {
                        _videoItems.append(BCOVPulseVideoItem.staticInit(dictionary: item))
                    }
                }
            }
            catch
            {
                 print("LisViewController Debug - Error retrieving library")
            }
        }
        
        return _videoItems
    }()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        if #available(tvOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { (status: ATTrackingManager.AuthorizationStatus) in
                print("Tracking authorization completed.")
            }
        }
    }

    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if (segue.identifier == "ViewControllerSegue")
        {
            let indexPath = tableView.indexPathForSelectedRow
            let videoItem = videoItems[indexPath?.item ?? 0]
            
            let destinationVC = segue.destination as? ViewController
            destinationVC?.videoItem = videoItem
        }
    }
}


// MARK: - UITableViewDelegate, UITableViewDataSource

extension ListViewController: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return "Basic Pulse tvOS Player"
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = UIColor.darkGray
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor.white
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return videoItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let item = videoItems[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)

        cell.textLabel?.text = item.title ?? ""
        cell.textLabel?.textColor = UIColor.black
        cell.detailTextLabel?.text = "\(item.category ?? "") \(item.tags?.joined(separator: ", ") ?? "")"
        cell.detailTextLabel?.textColor = UIColor.gray
        
        return cell
    }

}
