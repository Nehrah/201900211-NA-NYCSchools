//
//  ScoreViewController.swift
//
//
//  Created by Nethrah Ayyaswami on 2/11/2019.
//  Copyright © 2019 Nethrah Ayyaswami . All rights reserved.
//

import UIKit
struct Score {
    var reading: String
    var math: String
    var writing:String
    var testTakers = ""
    init(_ dictionary: [String: Any]) {
        self.reading = dictionary["sat_critical_reading_avg_score"] as! String
        self.math = dictionary["sat_math_avg_score"]  as! String
        self.writing = dictionary["sat_writing_avg_score"]  as! String
        self.testTakers = dictionary["num_of_sat_test_takers"]  as! String
    }
}
class ScoreTableViewCell:UITableViewCell{
    
    @IBOutlet weak var title_label: UILabel!
    @IBOutlet weak var detail_label:UILabel!
}

class ScoreViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate {
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    var databaseNumber :String = ""
    let  title_score = ["Critical Reading","Math","Writing","Test Takers"]
    var school_info = ["Name","Grades","Website"]
    var school_detail : [String] = []
    var score_detail: [String] = ["","","","",""]
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.myActivityIndicator.startAnimating()
        print(databaseNumber)
    }
    override func viewWillAppear(_ animated: Bool) {
        loadScore(info: school_detail)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Table View Delegate methods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sat_cell", for: indexPath) as! ScoreTableViewCell;
        switch indexPath.section {
        case 0:
            cell.title_label.text = title_score[indexPath.row]
            cell.detail_label.text = score_detail[indexPath.row]
            break
        case 1:
            cell.title_label.text = school_info[indexPath.row]
            cell.detail_label.text = school_detail[indexPath.row]
            break
        default:
            break
        }
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 4
        }
        else{
            
            return 3
        }
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0{
            return "SAT AVERAGE SCORE"
        }
        else{
            return "SCHOOL INFO"
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    //Function that loads the Score details
    func loadScore(info: [String]){
        myActivityIndicator.startAnimating()
        let listUrlString = "https://data.cityofnewyork.us/resource/734v-jeq5.json?dbn=" + String(databaseNumber)
        let myUrl = NSURL(string: listUrlString);
        let request = NSMutableURLRequest(url:myUrl! as URL);
        request.httpMethod = "GET";
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            if error != nil {
                print(error!.localizedDescription)
                ScoreViewController.performTaskInMainQueue {//Network Error handling
                            self.navigationController?.popViewController(animated: true)
                            self.dismiss(animated: true, completion: nil)
                            self.myActivityIndicator.stopAnimating()
                            return
                }
            }
            else{
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as? NSArray
                guard let jsonArray = json as? [[String: Any]] else {
                    return
                }
                if jsonArray .isEmpty{
                    self.score_detail = ["No Data","No Data","No Data","No Data"]
                }
                for dictionary in jsonArray{
                    print (dictionary)
                    let  score = Score.init(dictionary)
                    self.score_detail = [score.reading,score.math,score.writing,score.testTakers]
                }
                ScoreViewController.performTaskInMainQueue() {
                    self.myActivityIndicator.stopAnimating()
                    self.tableView.reloadData()
                }
            }
            catch {
                print(error)
                }
            }
        }
        task.resume()
        self.myActivityIndicator.stopAnimating()
    }
    
    //Async code handling
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
