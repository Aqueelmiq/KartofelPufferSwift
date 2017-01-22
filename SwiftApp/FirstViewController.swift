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
//import SwiftDate

class FirstViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    
    var speech:Bool = true;
    let synth = AVSpeechSynthesizer()
    var myUtterance = AVSpeechUtterance(string: "")
    
    
    let eventStore = EKEventStore()
    var calendar: EKCalendar?
    var savedEventId:String = ""
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @IBOutlet weak var data: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechPermissions()
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

    @IBAction func onSubmit(_ sender: Any) {
        
        
        if data.text == "" {
            startRecording()
        }
        if let dict = parse(input: data.text!) {
            
            
            var date = Date()
            var event: String! = ""
            
            if let set = dict["done"] as? NSDate{
                date = set as Date
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
            textToSpeech(text: event)
            
            if (EKEventStore.authorizationStatus(for: .event) != EKAuthorizationStatus.authorized) {
                eventStore.requestAccess(to: .event, completion: {
                    granted, error in
                    self.createEvent(eventStore: self.eventStore, title: event, startDate: date, endDate: date2)
                })
            } else {
                createEvent(eventStore: self.eventStore, title: event, startDate: date, endDate: date2)
            }

        
        }
        else {
            //Invalid input
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
    
    func parse(input: String) -> [String: Any]? {
        
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
        else if tokens.contains("in"){
            
            let date = NSDate()
            let index = tokens.index(of: "in")!
            if tokens.count > index + 2, let interval = Int(tokens[index+1]) {
                let type = tokens[index+2]
                switch type {
                    case "seconds", "second", "secs", "sec":
                        
                        dict["done"] = date.addingTimeInterval(TimeInterval(interval))                    case "minutes", "minute", "mins", "min":
                        dict["done"] = date.addingTimeInterval(TimeInterval(60*interval))
                    case "hours", "hour", "hr", "hrs":
                        dict["done"] = date.addingTimeInterval(TimeInterval(60*60*interval))
                    case "days", "day":
                        dict["done"] = date.addingTimeInterval(TimeInterval(24*60*60*interval))
                    case "months", "month":
                        dict["done"] = date.addingTimeInterval(TimeInterval(30*24*60*60*interval))
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
        else {
            return nil
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
        
        print("Hi")
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
        
    }
    
    func alert(title: String, msg:String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textToSpeech(text: String)
    {
        myUtterance = AVSpeechUtterance(string: text)
        myUtterance.rate = 0.3
        synth.speak(myUtterance)
    }
    
    
}


    


