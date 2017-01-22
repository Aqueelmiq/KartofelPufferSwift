//
//  FirstViewController.swift
//  SwiftApp
//
//  Created by Aqueel Miqdad on 1/21/17.
//  Copyright © 2017 ADAQ. All rights reserved.
//

import UIKit
import EventKit
import Speech
import AVFoundation
import Alamofire
//import SwiftDate

class FirstViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    
    var speech:Bool = true;
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    var calendar: EKCalendar?
    var savedEventId:String = ""
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @IBOutlet weak var data: UITextField!
    @IBOutlet weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechPermissions()
        //uploadEvent()
        
        self.stopButton.isHidden = true;
        
        let preferences = UserDefaults.standard
        let uid = "uid"

        if preferences.object(forKey: uid) == nil {
            let body = [
                "name": "Aditya Parakh",
                "friendsList": [],
                "reminderList": [],
                "notificationList": []
            ] as [String : Any]
            Alamofire.request(DB_URL + "users", method: .post, parameters: body, encoding: JSONEncoding.default)
                .responseJSON { response in
                    DispatchQueue.main.async {
                        if let JSON = response.result.value as? NSDictionary {
                            print(JSON)
                            if let id = JSON["id"] as? String {
                                preferences.set(id, forKey: uid)
                                user_id = id
                            }
                        }
                    }
            }
        } else {
            user_id = preferences.string(forKey: uid)!
        }
        print(user_id)
        loadFriends()
        loadReminders()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func speechPermissions() {
        //microphoneButton.isEnabled = false  //2
        speech = false
        
        speechRecognizer?.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.speech = true
            }
        }
    }

    @IBAction func startDication(_ sender: Any) {
        
        startRecording()
        self.stopButton.isHidden = false;
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        data.endEditing(true)
    }
    
    
    @IBAction func onSubmit(_ sender: Any) {
        
        let dict = parse(input: data.text!)
        print(dict)
        
        if let notifyee = dict["person"] as? String {
            
            if(notifyee.lowercased() == "me") {
                
                eventStore.requestAccess(to: .reminder, completion:
                    {(granted, error) in
                        if !granted {
                            print("Access to store not granted")
                        }
                })
                
                let reminder = EKReminder(eventStore: eventStore)
                
                if let titles = dict["recording"] as? [String] {
                    reminder.title = titles.joined(separator: " ")
                }
                if let calendar = eventStore.defaultCalendarForNewReminders() as? EKCalendar {
                    reminder.calendar = calendar
                }
                else {
                    reminder.calendar = eventStore.calendars(for: EKEntityType.reminder).first!
                }
                
                var date = Date()
                if let alarm = dict["done"] as? EKAlarm {
                    reminder.addAlarm(alarm)
                    date = alarm.absoluteDate ?? Date()
                }
                
                
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
                
                let person = dict["person"] as! String
                for friend in friendList {
                    
                    if(friend.lowercased().range(of: (person.lowercased()))) != nil {
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
            alert(title: "Reminder Set", msg: "For " + "reminder")
            
        }

        
        /*
        else {
            alert(title: "We didnt understand you", msg: "Please try saying that again or type it in")
        }*/
        
        
        
        
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
    
    func parse(input: String) -> [String:Any] {
        
        /*
         |
         | Date, Minute, Hours, Day, Recording, Person
         |
         */
        
        var dict:[String: Any] = [:]
        var x = input.lowercased()
        var recorded:[String] = []
        var tokens = x.characters.split(separator: " ").map(String.init)
        
        
        //Look for person
        for token in tokens {
            for friend in friendList {
                if (friend.lowercased().range(of: token) != nil) {
                    tokens = tokens.filter({$0 != token})
                    dict["person"] = token
                    break;
                }
            }
        }
        
        // Set Date
        if !x.contains("in") {
            
            var remove = ""
            
            //Look for year
            for i in 0..<tokens.count {
                if let val = Int(tokens[i]) {
                    if val >= 2017{
                        dict["year"] = val
                        remove = tokens[i]
                        tokens = tokens.filter({$0 != remove})
                    }
                    else if val <= 31{
                        if(tokens[i].contains("th") || tokens[i].contains("st") || tokens[i].contains("rd") || tokens[i].contains("rd") )  {
                            dict["day"] = val
                        }
                        else if i < tokens.count - 1 && months.contains(tokens[i+1].lowercased()) {
                            dict["day"] = val
                        }
                        else if i < tokens.count - 1 && tm.contains(tokens[i+1].lowercased()) {
                            dict["date"] = val
                            dict["eve"] = "am"
                        }
                    }
                }
            }
            
            
            //Look for month
            for token in tokens {
                if months.contains(token) {
                    dict["month"] = monthsToNum[token]
                    remove = token
                }
            }
            
            dict["done"] = EKAlarm()
            tokens = tokens.filter({$0 != remove})
            tokens = tokens.filter({$0 != "remind"})
            tokens = tokens.filter({$0 != "me"})
            tokens = tokens.filter({$0 != ""})
            
            for word in tokens {
               recorded.append(word)
            }
            
        }
        else if tokens.contains("in"){
            
            let date = NSDate()
            let index = tokens.index(of: "in")!
            if tokens.count > index + 2, let interval = Int(tokens[index+1]) {
                let type = tokens[index+2]
                switch type {
                    case "seconds", "second", "secs", "sec":
                        
                        dict["done"] = EKAlarm(relativeOffset: TimeInterval(interval))
                    case "minutes", "minute", "mins", "min":
                        dict["done"] = EKAlarm(relativeOffset: TimeInterval(60*interval))
                    case "hours", "hour", "hr", "hrs":
                        dict["done"] = EKAlarm(relativeOffset: TimeInterval(60*60*interval))
                    case "days", "day":
                        dict["done"] = EKAlarm(relativeOffset: TimeInterval(24*60*60*interval))
                    case "months", "month":
                        dict["done"] = EKAlarm(relativeOffset: TimeInterval(30*24*60*60*interval))
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
    
    func startRecording() {
        
        if recognitionTask != nil {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                self.data.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.speech = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        data.text = "Say something, I'm listening!"
        
    }
    

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            speech = true
        } else {
            speech = false
        }
    }
    
    @IBAction func stop(_ sender: Any) {
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        self.stopButton.isHidden = true;
        
    }

    
    func textToSpeech(text: String)
    {
        myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = 0.3
        synth.speak(myUtterance)
    }
    
    
    func alert(title: String, msg:String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func loadReminders() {
        
        Alamofire.request(DB_URL + "users/" + user_id + "/reminder")
            .responseJSON { response in
                
                DispatchQueue.main.async {
                    //print(response.request)
                    if let JSON = response.result.value as? NSDictionary{
                        //print(JSON)
                        if let reminders = JSON["reminders"] as? NSArray {
                            for reminder in reminders {
                                if let rem = reminder as? NSDictionary {
                                    if let id = rem["_id"] as? String, let name = rem["name"] as? String, let time = rem["time"] as? String {
                                        userReminders.append(Reminder(_id: id, name: name, time: time));
                                    }
                                }
                            }
                            print(reminders.count)
                        }
                    }
                }
        }

    
    }
    
    func loadFriends() {
        
        Alamofire.request(DB_URL + "users/" + user_id)
            .responseJSON { response in
                DispatchQueue.main.async {
                    if let JSON = response.result.value as? NSDictionary{
                        if let user = JSON["user"] as? NSDictionary {
                            if let frnds = user["friendsList"] as? NSArray {
                                
                                for friend in frnds {
                                    let item = friend as! String
                                    //print(item)
                                    Alamofire.request(DB_URL + "users/" + item)
                                        .responseJSON { response in
                                            DispatchQueue.main.async {
                                                //print(response)
                                                if let JSON = response.result.value as? NSDictionary{
                                                    if let user = JSON["user"] as? NSDictionary{
                                                        if let name = user["name"] as? String {
                                                            friendList.append(name)
                                                            friendId[name] = item
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                    
                                    
                                }
                            }
                        }
                    }
                }
        }
    }


    
    
}


    


