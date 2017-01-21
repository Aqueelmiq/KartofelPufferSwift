//
//  FirstViewController.swift
//  SwiftApp
//
//  Created by Aqueel Miqdad on 1/21/17.
//  Copyright © 2017 ADAQ. All rights reserved.
//

import UIKit
import EventKit
//import SwiftDate

class FirstViewController: UIViewController {
    
    let eventStore = EKEventStore()
    var calendar: EKCalendar?
    var savedEventId:String = ""

    @IBOutlet weak var data: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func Test(_ sender: Any) {
        //let dict = parse(input: "Remind me to wake up Bob tomorrow at 5 AM")
        
    }
    @IBAction func onSubmit(_ sender: Any) {
        
        let dict = parse(input: data.text!)
        var date = Date()
        var event: String! = ""
        
        if let set = dict["done"] as? Date{
            date = set
        }
        else {
            
            // create a new DateInRegion on 2002-03-04 at 05:06:07.87654321 (+/-10) in Region.Local()
            let now = Date()
            
            // *** Get components from date ***
            var components = timeCalendar.dateComponents(unitFlags, from: now)
            
            if let minutes = dict["hours"] as? Int {
                components.hour = minutes
            }
            else {
                components.hour = 8
            }
            if let minutes = dict["minutes"] as? Int {
                components.minute = minutes
            }
            else {
                components.minute = 0
            }
            if let date = dict["date"] as? Int {
                switch date {
                case 0:
                    components.day = components.day ?? 1
                    break
                case 1:
                    components.day = components.day! + 1
                    break
                case let date where date > 100:
                    components.month = date
                    components.day = dict["day"] as! Int?
                    break;
                default:
                    print("weird month/date")
                }
            }
            else {
                components.minute = 0
            }
            
            date = timeCalendar.date(from: components)!
        
        }
        
        
        if let recording = dict["recorded"] as? [String] {
            event = recording.joined(separator: " ")
        }
        else {
            event = "Reminder"
        }
        
        
        
        let date2 = Date(timeInterval: TimeInterval(5*60), since: date)
    
        
        print(event)
        
        if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
            eventStore.requestAccess(to: .event, completion: {
                granted, error in
                self.createEvent(eventStore: self.eventStore, title: event, startDate: date, endDate: date2)
            })
        } else {
            createEvent(eventStore: self.eventStore, title: event, startDate: date, endDate: date2)
        }
        
        
    }
    
    // Creates an event in the EKEventStore. The method assumes the eventStore is created and
    // accessible
    func createEvent(eventStore: EKEventStore, title: String, startDate: Date, endDate: Date) {
        let event = EKEvent(eventStore: eventStore)
        
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        do {
            try eventStore.save(event, span: .thisEvent)
            savedEventId = event.eventIdentifier
            print(savedEventId)
        } catch {
            print("Bad things happened")
        }
    }
    
    // Removes an event from the EKEventStore. The method assumes the eventStore is created and
    // accessible
    func deleteEvent(eventStore: EKEventStore, eventIdentifier: String) {
        let eventToRemove = eventStore.event(withIdentifier: eventIdentifier)
        if (eventToRemove != nil) {
            do {
                try eventStore.remove(eventToRemove!, span: .thisEvent)
            } catch {
                print("Bad things happened")
            }
        }
    }
    
    // Responds to button to add event. This checks that we have permission first, before adding the
    // event
    func addEvent() {
        let eventStore = EKEventStore()
        
        let startDate =
            Date()
        let endDate = startDate.addingTimeInterval(60 * 60) // One hour
        
        if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
            eventStore.requestAccess(to: .event, completion: {
                granted, error in
                self.createEvent(eventStore: eventStore, title: "DJ's Test Event", startDate: startDate, endDate: endDate)
            })
        } else {
            createEvent(eventStore: eventStore, title: "DJ's Test Event", startDate: startDate, endDate: endDate)
        }
    }
    
    
    // Responds to button to remove event. This checks that we have permission first, before removing the
    // event
    func removeEvent(sender: UIButton) {
        let eventStore = EKEventStore()
        
        if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
            eventStore.requestAccess(to: .event, completion: { (granted, error) -> Void in
                self.deleteEvent(eventStore: eventStore, eventIdentifier: self.savedEventId)
            })
        } else {
            deleteEvent(eventStore: eventStore, eventIdentifier: savedEventId)
        }
        
    }
    
    func parse(input: String) -> [String: Any] {
        
        /*
         |
         | Date, Minute, Hours, Day, Recording, Person
         |
         */
        
        var dict:[String: Any] = [:]
        var x = input.lowercased()
        var recorded:[String] = []
        var tokens = x.characters.split(separator: " ").map(String.init)
        if !x.contains("in") {
            
            for i in 0..<tokens.count {
                let word = tokens[i];
                switch word {
                case "remind":
                    break
                case "me":
                    dict["person"] = word
                    break
                case "to":
                    break
                case "":
                    break;
                default:
                    if word.contains("th") || word.contains("rd") || word.contains("st") || word.contains("nd") {
                        if let day = Int(word) {
                            dict["day"] = day
                        }
                    }
                    if let time = Int(word) {
                        dict["hour"] = time
                        if word.contains(":") {
                            let arr = word.characters.split(separator: ":").map(String.init)
                            if let val = Int(arr[1]) {
                                dict["minutes"] = val
                            }
                        }
                    }
                    else if let val = timeKeys[word] {
                        dict["date"] = val
                        if val > 100 {
                            if let next = Int(tokens[i+1]) {
                                dict["day"] = next
                            }
                        }
                    }
                    else if tokens[i-1] == "remind" {
                        dict["person"] = word
                    }
                    else {
                        recorded.append(word)
                    }
                    break;
                }
            }
            
        }
        else {
            
            var date = Date()
            let index = tokens.index(of: "in")!
            if tokens.count > index + 2, let interval = Int(tokens[index+1]) {
                let type = tokens[index+2]
                switch type {
                    case "seconds", "second", "secs", "sec":
                        dict["done"] = date.addTimeInterval(TimeInterval(interval))
                    case "minutes", "minute", "mins", "min":
                        dict["done"] = date.addTimeInterval(TimeInterval(60*interval))
                    case "hours", "hour", "hr", "hrs":
                        dict["done"] = date.addTimeInterval(TimeInterval(60*60*interval))
                    case "days", "day":
                        dict["done"] = date.addTimeInterval(TimeInterval(24*60*60*interval))
                    case "months", "month":
                        dict["done"] = date.addTimeInterval(TimeInterval(30*24*60*60*interval))
                    default:
                        print("Improper interval format")
                }
            }
            else {
                print("No interval given")
            }
            
            for i in 0..<index {
                let word = tokens[i]
                switch word {
                case "remind":
                    break
                case "me":
                    dict["person"] = word
                    break
                case "to":
                    break
                case "":
                    break;
                default:
                    recorded.append(word)
                }
            }
            
        }
        dict["recorded"] = recorded
        return dict
    }
    
}


    


