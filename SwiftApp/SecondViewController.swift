//
//  SecondViewController.swift
//  SwiftApp
//
//  Created by Aqueel Miqdad on 1/21/17.
//  Copyright © 2017 ADAQ. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    

    @IBOutlet weak var friendsTable: UITableView!
    
    var friends:[String] = ["Mete", "Aqueel", "Paolo"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.friendsTable.delegate = self
        self.friendsTable.dataSource = self
        // Do any additional setup after loading the view, typically from a nib.
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
        return 70
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let match = self.friends[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell") as? ResultCell {
            cell.name.text = match
            print("Hello")
            return cell
        }
        else {
            return ResultCell()
        }
        
        
    }

    /*
     
     FUNCS

     */

    @IBAction func addFriend(_ sender: Any) {
        print("Hello")
    }

}

