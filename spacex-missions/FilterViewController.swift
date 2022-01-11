//
//  FilterViewController.swift
//  spacex-missions
//
//  Created by Rafael Giusti on 1/5/22.
//
import UIKit
import CoreData

class FilterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var successLaunchSwitch: UISwitch!
    @IBOutlet weak var launchDateSort: UISegmentedControl!
    @IBOutlet weak var yearsPickerTable: UITableView!
    
    let launchesYears: [Int] = Array(stride(from: 2030, to: 1999, by: -1))
    
    override func viewDidLoad() {
        //query and load years
        yearsPickerTable.reloadData()
        yearsPickerTable.scrollToRow(at: IndexPath(row: 8, section: 0), at: .top, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return launchesYears.count
    }
    
    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //get basic cell with year and checkmark
        let yearCell = tableView.dequeueReusableCell(withIdentifier: "YearCell", for: indexPath)
        
        yearCell.accessoryType = tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false ? .checkmark:.none
        
        yearCell.textLabel?.text = String(format: "%d", launchesYears[indexPath.row])
        return yearCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
    func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        for cell in tableView.visibleCells {
            cell.accessoryType = cell.isSelected ? .checkmark:.none
        }
    }
    
}
