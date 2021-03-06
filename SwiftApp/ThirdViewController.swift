//
//  ThirdViewController.swift
//  SwiftApp
//
//  Created by Aqueel Miqdad on 1/21/17.
//  Copyright © 2017 ADAQ. All rights reserved.
//

import UIKit

class ThirdViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var reminderTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reminderTable.delegate = self;
        reminderTable.dataSource = self;
        reminderTable.reloadData()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
     
     TableView Stuff
     
     */
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 90
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  userReminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let match = userReminders[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ReminderCell") as? ReminderCell {
            cell.name.text = match.name
            cell.due.text = match.time
            return cell
        }
        else {
            return ReminderCell()
        }
        
        
    }

}
