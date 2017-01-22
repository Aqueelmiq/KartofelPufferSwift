//
//  InputViewController.swift
//  SwiftApp
//
//  Created by Aqueel Miqdad on 1/22/17.
//  Copyright © 2017 ADAQ. All rights reserved.
//

import UIKit
import EventKit
import Alamofire

class InputViewController: UIViewController {

    @IBOutlet weak var person: UITextField!
    @IBOutlet weak var event: UITextField!
    @IBOutlet weak var picker: UIDatePicker!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.event.endEditing(true)
        person.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onSubmit(_ sender: Any) {
        
        if let notifyee = person.text! as? String {
            
            if(notifyee.lowercased() == "me") {
            
                eventStore.requestAccess(to: .reminder, completion:
                    {(granted, error) in
                        if !granted {
                            print("Access to store not granted")
                        }
                })
                
                let reminder = EKReminder(eventStore: eventStore)
                
                reminder.title = event.text!
                if let calendar = eventStore.defaultCalendarForNewReminders() as? EKCalendar {
                    reminder.calendar = calendar
                }
                else {
                    reminder.calendar = eventStore.calendars(for: EKEntityType.reminder).first!
                }
                
                let date = picker.date
                let alarm = EKAlarm(absoluteDate: date)
                
                reminder.addAlarm(alarm)
            
                
                do {
                    try eventStore.save(reminder, commit: true)
                } catch let error {
                    print("Reminder failed with error \(error.localizedDescription)")
                }
                
                let body = [
                    "name": reminder.title,
                    "time": "\(date)"
                ]
                
                Alamofire.request(DB_URL + "users/" + user_id + "/reminder", method: .post, parameters: body, encoding: JSONEncoding.default)
                    .responseJSON { response in
                        DispatchQueue.main.async {
                            if let JSON = response.result.value as? NSDictionary {
                                print(JSON)
                            }
                        }
                }

                
            }
            else {
                for friend in friendList {
                    if(friend.lowercased().range(of: (person.text?.lowercased())!)) != nil {
                        if let uid = friendId[friend] {
                            
                            Alamofire.request(DB_URL + "users/" + uid + "/reminder", method: .post, parameters: nil, encoding: JSONEncoding.default)
                                .responseJSON { response in
                                    DispatchQueue.main.async {
                                        if let JSON = response.result.value as? NSDictionary {
                                            print(JSON)
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            alert(title: "Reminder Set", msg: "For " + self.event.text!)
            
        }
        
    }
    
    func alert(title: String, msg:String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
