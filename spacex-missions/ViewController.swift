//
//  ViewController.swift
//  spacex-missions
//
//  Created by Rafael Giusti on 1/5/22.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var defaultCompany: Company? {
        didSet{
            if (defaultCompany != nil) {
                DispatchQueue.main.async {
                    self.loadCompany()
                }
            }
        }
    }
    var launches = [Launch]()
    var yearsFilter = [Int]()
    var successLaunchesFilter = false
    var dateSorting: Int = UISegmentedControl.noSegment
    
    @IBOutlet weak var companyDetailsLabel: UILabel!
    @IBOutlet weak var launchesTableView: UITableView!
    @IBOutlet weak var launchesCountLabel: UILabel!
    
    @IBAction func unwindWithFilter(_ unwindSegue: UIStoryboardSegue) {
        // Use data from the view controller which initiated the unwind segue
        if let filterVC = unwindSegue.source as? FilterViewController {
            yearsFilter.removeAll()
            if let selectedYears = filterVC.yearsPickerTable.indexPathsForSelectedRows{
                for yearSelection in selectedYears {
                    yearsFilter.append(filterVC.launchesYears[yearSelection.row])
                }
                yearsFilter.sort()
            }
            dateSorting = filterVC.launchDateSort.selectedSegmentIndex
            
            print("yearsFilter",yearsFilter)
            print("dateSorting",dateSorting)
            
            if yearsFilter.isEmpty && dateSorting == UISegmentedControl.noSegment && successLaunchesFilter == filterVC.successLaunchSwitch.isOn{
                //no updates, skip reloading table
            }else{
                print("successLaunchesFilter",successLaunchesFilter)
                successLaunchesFilter = filterVC.successLaunchSwitch.isOn
                loadLaunches()
            }
        }
        
        
    }
    
    @IBAction func unwindNoFilter(_ unwindSegue: UIStoryboardSegue) {
        // Use data from the view controller which initiated the unwind segue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let navTitleView = UIImageView(image: UIImage(named: "bannerBackgroundRighty"))
        navTitleView.contentMode = .scaleAspectFit
        self.navigationItem.titleView = navTitleView

        /*no longer needed, configured on storyboard trough: translucent, and bar tint
        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        standardAppearance.backgroundColor = #colorLiteral(red: 0.2078431373, green: 0.2078601718, blue: 0.207810849, alpha: 1)
        let navBar = self.navigationController!.navigationBar
        navBar.standardAppearance = standardAppearance
        navBar.scrollEdgeAppearance = standardAppearance
        navBar.compactAppearance = standardAppearance
         if #available(iOS 15.0, *) { // For compatibility with earlier iOS.
            navBar.compactScrollEdgeAppearance = compactAppearance
        }*/
        
        //Read and set default company from core data
        let queryCompanies : NSFetchRequest<Company> = Company.fetchRequest()
        
        do{
            let companies = try self.context.fetch(queryCompanies)
            if companies.count > 0 {
                defaultCompany = companies[0]
            }
            else{
                defaultCompany = nil
            }
        } catch {
            print("Error loading companies \(error)")
            defaultCompany = nil
        }
        //ifempty Company--> Initial loading: pull and store both company, and then launches data
        if (defaultCompany == nil){
            print("Loading Company Data")
            pullAppData()
        }
        else{
            
            loadLaunches()
        }
        
        print(defaultCompany?.name)
        print(defaultCompany)
        
        //otherwise, just check for any new launches --todo
        
        
     }
    
    //Initial Loading. Load Company, then Launches Data
    func pullAppData(){
        
        if let url = URL(string: "https://api.spacexdata.com/v4/company") {
            
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: url)
            { (data, response, error) in
                if error != nil {
                    print(error!)
                    return
                }
                if let safeData = data {
                    print(safeData)
                    //print(String(data: safeData, encoding: .utf8)!)
                    
                    let decoder = JSONDecoder()
                    do {
                        decoder.userInfo[CodingUserInfoKey(rawValue: "managedObjectContext")!] = self.context
                        
                        let decodedData = try decoder.decode(Company.self, from: safeData)
                        //print("company decodedData",decodedData)
                        self.defaultCompany = decodedData
                        self.pullLaunches()
                        
                    } catch {
                        print("Decoder Failed: ", error)
                    }
                }
            }
            task.resume()
        }
    }
    
    func pullLaunches() {
        
        let requestBody = [
            "query": [String:Any](),
            "options": ["pagination":false,
                        "limit":4,
                        "page":2,
                        "select": ["name":1,"date_local":1,"success":1,"links":1,"flight_number-off":1,"details":1],
                        "populate": [
                            "path":"rocket",
                            "select":["name":1,"type":1]
                        ]
            ]
        ]
        
        if let url = URL(string: "https://api.spacexdata.com/v4/launches/query") {
            let session = URLSession(configuration: .default)
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let jsonData = try? JSONSerialization.data(
                    withJSONObject: requestBody,
                    options: [.prettyPrinted]
            ){
                urlRequest.httpBody = jsonData
            }
            print("httpBody:",String(data: urlRequest.httpBody!, encoding: .utf8)!)
            print("Content-Type:", urlRequest.value(forHTTPHeaderField: "Content-Type")!)
            
            let task = session.dataTask(with: urlRequest) { (data, response, error) in
                if error != nil {
                    print(error!)
                    //self.delegate?.didFailWithError(error: error!)
                    return
                }
                if let safeData = data {

                    print(safeData)
                    //print(String(data: safeData, encoding: .utf8)!)
                    
                    let decoder = JSONDecoder()
                    do {
                        decoder.userInfo[CodingUserInfoKey(rawValue: "managedObjectContext")!] = self.context
                        decoder.userInfo[CodingUserInfoKey(rawValue: "relatedEntity")!] = self.defaultCompany
                        
                        _ = try decoder.decode(LaunchesDocs.self, from: safeData)
                        //print("Launches decodedData",decodedData)
                        //done pulling data, now save context
                        DispatchQueue.main.async {
                            (UIApplication.shared.delegate as! AppDelegate).saveContext()
                            self.loadLaunches()
                        }
                        
                        
                    } catch {
                        print("Decoder Failed: ", error)
                    }
                    
                }
            }
            task.resume()
        }
    }
    
    func loadCompany(){
        if let c = defaultCompany {
            
            let df = DateFormatter()
            df.dateFormat = "yyyy"
            let mf = NumberFormatter()
            mf.numberStyle = .currency //.currencyISOCode
            mf.maximumFractionDigits = 0
            //locale display thousand separator on %d
            self.companyDetailsLabel.text = String(format: self.companyDetailsLabel.text!, locale: Locale.current, c.name!, c.founder!, df.string(from:c.founded!), c.employees, c.launchSites, mf.string(from: c.valuation!)!)
        }
    }
    
    func loadLaunches() {
        
        let launchesFetchRequest: NSFetchRequest<Launch> = Launch.fetchRequest()
        
        if yearsFilter.count > 0 {
            let df = DateFormatter()
            df.dateFormat = "yyyy"
            
            for yearSelection in yearsFilter {
                if let yearStartDate = df.date(from: String(yearSelection)),
                   let yearEndDate = df.date(from: String(yearSelection+1))
                {
                    let btwPredicate = NSPredicate(format: "datetime >= %@ AND datetime < %@", yearStartDate as NSDate, yearEndDate as NSDate)
                    if let existingPredicate = launchesFetchRequest.predicate {
                        launchesFetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [existingPredicate, btwPredicate])
                    }else{
                        launchesFetchRequest.predicate = btwPredicate
                    }

                }else{
                    print("Date Range Predicate Error for yearSelection:",yearSelection)
                    continue
                }
            }
        }
            
        if (successLaunchesFilter) {
            let successFilterPredicate = NSPredicate(format: "launchSuccess = true")
            if let existingPredicate = launchesFetchRequest.predicate {
                launchesFetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [ successFilterPredicate,existingPredicate])
            }else{
                launchesFetchRequest.predicate = successFilterPredicate
            }
        }
        
        if (dateSorting != UISegmentedControl.noSegment){
            launchesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "datetime",
                                                                     ascending: dateSorting == 0)]
        }
 
        
        do{
            self.launches = try self.context.fetch(launchesFetchRequest)
            print("launches.count",launches.count)
            self.launchesCountLabel.text = String(format: "  LAUNCHES (count: %d)", launches.count)
            if launches.count > 0 {
                print(launches[0].missionName!)
                //print(launches[0])
            }
        } catch {
            print("Error loading launches \(error)")
        }
       
        self.launchesTableView.reloadData()
        
    }
    
    //MARK: - Tableview Datasource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return launches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LaunchCell", for: indexPath) as! LaunchCell
        
        let launch = launches[indexPath.row]

        cell.missionName?.text = launch.missionName
        if let patchImgURL = launch.patchImg,
           let imgData = try? Data(contentsOf: patchImgURL, options: Data.ReadingOptions.alwaysMapped) {
            cell.patchImg.image = UIImage(data: imgData)
        }else{
            cell.patchImg.image = UIImage(systemName: "questionmark.square.dashed")
        }
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd 'at' HH:mm"
        cell.datetimeLabel?.text = df.string(from: (launch.datetime)!)
        cell.rocketLabel?.text = "\(launch.rocketName!) / \(launch.rocketType!)"
        
        let dcf = DateComponentsFormatter()
        dcf.allowedUnits = .day
        dcf.unitsStyle = .full

        if (Date() > launch.datetime!) {
            cell.launchDaysIntervalLabel?.text = "Days Since Now:"
            cell.launchDaysInterval?.text = dcf.string(from: launch.datetime!, to: Date())
            cell.successImg.image = launch.launchSuccess ? UIImage(systemName: "checkmark") : UIImage(systemName: "xmark")
            cell.successImg.tintColor = launch.launchSuccess ? .systemGreen : .systemRed
        }
        else{
            cell.launchDaysIntervalLabel?.text = "Days From Now:"
            cell.launchDaysInterval?.text = dcf.string(from: Date(), to: launch.datetime!)
            cell.successImg.image = UIImage(systemName: "questionmark")
            cell.successImg.tintColor = .darkGray
        }
        
        return cell
    }
    
    // MARK: - TableView Delegates
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = self.launchesTableView.indexPathForSelectedRow {
            //self.launchesTableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        self.launchesTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        return UIContextMenuConfiguration(
            identifier: nil, previewProvider: nil,
            actionProvider:
                {
                    suggestedActions in
                    let articleAvailability = self.launches[indexPath.row].article != nil ? UIMenuElement.Attributes.init():UIMenuElement.Attributes.disabled
                    let openArticle =
                        UIAction(title: NSLocalizedString("Article", comment: ""),
                                 image: UIImage(systemName: "doc.text"),
                                 attributes: articleAvailability) { action in
                            self.openLinkOnBrowser(link: self.launches[indexPath.row].article)
                        }
                    let wikiAvailability = self.launches[indexPath.row].wikipedia != nil ? UIMenuElement.Attributes.init():UIMenuElement.Attributes.disabled
                    let openWikipedia =
                        UIAction(title: NSLocalizedString("Wikipedia", comment: ""),
                                 image: UIImage(systemName:"text.below.photo"),
                                 attributes: wikiAvailability) { action in
                            self.openLinkOnBrowser(link: self.launches[indexPath.row].wikipedia)
                        }
                    
                    let mediaLink: URL? = self.launches[indexPath.row].webcast != nil ?
                        self.launches[indexPath.row].webcast
                        : self.launches[indexPath.row].youtubeId != nil ?
                        URL(string: String(format: "https://youtu.be/%@",self.launches[indexPath.row].youtubeId!))
                        : nil
                    let mediaAvailability = mediaLink != nil ? UIMenuElement.Attributes.init():UIMenuElement.Attributes.disabled
                    let openVideo =
                        UIAction(title: NSLocalizedString("Video", comment: ""),
                                 image: UIImage(systemName: "arrow.up.right.video"),
                                 attributes: mediaAvailability) { action in
                            self.openLinkOnBrowser(link: mediaLink)
                        }
                                                
                    return UIMenu(title: "More Launch Details",
                                  children: [openArticle, openWikipedia, openVideo])
            })
    }
    
    func openLinkOnBrowser(link: URL?){
        if let url = link{
            UIApplication.shared.open(url)
        }
    }
    func openLinkOnBrowser(link: String){
        if let url = URL(string: link) {
            self.openLinkOnBrowser(link: url)
        }
    }
    
}



