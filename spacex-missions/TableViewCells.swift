//
//  TableViewCells.swift
//  spacex-missions
//
//  Created by Rafael Giusti on 1/5/22.
//
import UIKit

class LaunchCell: UITableViewCell {
    
    @IBOutlet weak var patchImg: UIImageView!
    
    @IBOutlet weak var missionName: UILabel!
    @IBOutlet weak var datetimeLabel: UILabel!
    @IBOutlet weak var rocketLabel: UILabel!
    @IBOutlet weak var launchDaysIntervalLabel: UILabel!
    @IBOutlet weak var launchDaysInterval: UILabel!
    
    @IBOutlet weak var successImg: UIImageView!
    
}
