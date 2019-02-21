
//  SchoolViewController.swift
//
//  Created by Nethrah Ayyaswami on 2/11/2019.
//  Copyright © 2019 Nethrah Ayyaswami . All rights reserved.
//
import UIKit
struct school_info {
    var dbn: String
    var school_name: String
    var location:String
    var website:String
    var phone:String
    var grade:String
    init(_ dictionary: [String: Any]) {
        self.dbn = dictionary["dbn"] as! String
        self.school_name = dictionary["school_name"]  as! String
        self.location = dictionary["location"]  as! String
        self.phone = dictionary["phone_number"] as! String
        self.grade = dictionary["grades2018"] as! String
        if let index = (location.range(of: "(")?.lowerBound)
        {
            self.location = String(location.prefix(upTo: index))
        }
        self.website = dictionary["website"] as! String
    }
}
class SchoolViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var privateList = [school_info]()
    var filteredList = [school_info]()
    var networkError = false
    var fromIndex = 0
    let batchSize = 1
    var searchActive : Bool = false
    var searchString = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.topItem?.title = "NYC High School"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMoreItems()
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
 //Function that returns the search results by calling the Search Url and append the results in an array
    func searchItems(){
        let listSearchString = "https://data.cityofnewyork.us/resource/97mf-9njv.json?$where=school_name%20like%27%25"+String(searchString)+"%25%27&$order=school_name%20ASC"
        var myUrl : NSURL
        myUrl = NSURL(string: listSearchString)!
        let request = NSMutableURLRequest(url:myUrl as URL);
        request.httpMethod = "GET";
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            if error != nil {
                print(error!.localizedDescription)
                self.networkErrorHandle()
                return
                
            }
            else{
                do {
                    let json = try JSONSerialization.jsonObject(with: data!) as? NSArray
                    guard let jsonArray = json as? [[String: Any]] else {
                        return
                    }
                    if jsonArray .isEmpty{
                        let alert = UIAlertController(title: "Search Alert", message: "Please type a valid school", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { action in
                            self.searchBar.text?.removeAll()
                            self.searchActive = false
                            SchoolViewController.performTaskInMainQueue {
                                self.tableView.reloadData()
                                self.activityIndicator.stopAnimating()
                            }
                        }))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }else{
                        for dic in jsonArray{
                            self.filteredList.append(school_info(dic))
                            SchoolViewController.performTaskInMainQueue {
                                self.tableView.reloadData()
                                self.activityIndicator.stopAnimating()
                            }
                        }
                    }
                    
                }
                catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
    
    //Function that returns the school data and append the results in an array.
    // Url returns the data with a limit of 20. Start index is kept track to load the next set of high school items.
    
    func loadItemsNow(listType:String){
        let listUrlString = "https://data.cityofnewyork.us/resource/97mf-9njv.json?$limit=" + String(fromIndex + batchSize) + "&$offset=" + String(fromIndex)
        var myUrl : NSURL
        myUrl = NSURL(string: listUrlString)!
        let request = NSMutableURLRequest(url:myUrl as URL);
        request.httpMethod = "GET";
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            if error != nil {
                print(error!.localizedDescription)
                self.networkErrorHandle()
                
            }
            else{
                do {
                    let json = try JSONSerialization.jsonObject(with: data!) as? NSArray
                    guard let jsonArray = json as? [[String: Any]] else {
                        return
                    }
                    var items = self.privateList
                    for dic in jsonArray{
                        items.append(school_info(dic))
                        if self.fromIndex < items.count {
                            self.privateList = items
                            self.fromIndex = items.count
                            SchoolViewController.performTaskInMainQueue {
                                self.tableView.reloadData()
                                self.activityIndicator.stopAnimating()
                            }
                        }
                    }
                }
                    
                catch {
                    print(error)
                }
            }
        }
        task.resume()
        
    }
    func loadMoreItems() {
        loadItemsNow(listType: "privateList")
    }
    
    // Function that transfer the school details to the Next view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let indexPath = tableView.indexPathForSelectedRow
        var info_array = [String]()
        // let index = indexPath?.row
        let destinationVC = segue.destination as! ScoreViewController
        if searchActive == true && filteredList .isEmpty != true{
            info_array = [self.filteredList[(indexPath?.row)!].school_name,self.filteredList[(indexPath?.row)!].grade,self.filteredList[(indexPath?.row)!].website]
            destinationVC.databaseNumber = self.filteredList[(indexPath?.row)!].dbn
            destinationVC.school_detail = info_array
        }
        else{
            info_array = [self.privateList[(indexPath?.row)!].school_name,self.privateList[(indexPath?.row)!].grade,self.privateList[(indexPath?.row)!].website]
            destinationVC.databaseNumber = self.privateList[(indexPath?.row)!].dbn
            destinationVC.school_detail = info_array
        }
    }
    func networkErrorHandle()
    {
        SchoolViewController.performTaskInMainQueue {
            self.networkError = true
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }
    //Async task Error handling
    class func performTaskInMainQueue(task: @escaping ()->()) {
        DispatchQueue.main.async {
            task()
        }
    }
    class func performTaskInBackground(task:@escaping () throws -> ()) {
        DispatchQueue.global(qos: .background).async {
            do {
                try task()
            } catch let error as NSError {
                print("error in background thread:\(error.localizedDescription)")
            }
        }
    }
}

extension SchoolViewController: UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate {
    //TableView Delegate Method
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if networkError == true{
            return 1
        }
        else{
            if searchActive == true{
                return filteredList.count
            }
            else{
                return privateList.count
            }
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if networkError == true{
            tableView.register(UINib(nibName: "NetworkErrorViewCell", bundle: nil), forCellReuseIdentifier: "Error")
            let cell = tableView.dequeueReusableCell(withIdentifier: "Error", for: indexPath) as! NetworkErrorViewCell
            cell.textLabel?.text = "Internet Connection Offline"
            return cell
        }
        else{
            if searchActive == true {
                print(filteredList)
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SchoolViewCell
                cell.school_name_label?.text = filteredList[indexPath.row].school_name
                cell.address_label?.text = filteredList[indexPath.row].location
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SchoolViewCell
                cell.school_name_label?.text = privateList[indexPath.row].school_name
                cell.address_label?.text = privateList[indexPath.row].location
                if indexPath.row == privateList.count - 1 {
                    loadMoreItems()
                }
                return cell
            }
        }
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print(self.privateList[indexPath.row])
        
    }
    // search View Delegate Method
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        //searchActive = false;
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.showsCancelButton = true
        tableView.reloadData()
        searchBar.endEditing(true)
        searchActive = false;
        loadMoreItems()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        filteredList.removeAll()
        searchBar.resignFirstResponder()
        searchString = searchBar.text!
        searchItems()
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
}
