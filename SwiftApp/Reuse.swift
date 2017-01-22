//
//  Reuse.swift
//  SwiftApp
//
//  Created by Aqueel Miqdad on 1/21/17.
//  Copyright © 2017 ADAQ. All rights reserved.
//

import Foundation
import EventKit

// *** create calendar object ***
var timeCalendar = NSCalendar.current
var eventStore = EKEventStore()
let unitFlags = Set<Calendar.Component>([.minute, .hour, .day, .month, .year])

let timeKeys = [
    
    "today":    0,
    "tomorrow": 1,
    "jan": 101,
    "january": 101,
    "feb": 102,
    "february": 102,
    "march": 103,
    "mar": 103,
    "april": 104,
    "apr": 104,
    "may": 105,
    "june": 106,
    "jun": 106,
    "july": 107,
    "jul": 107,
    "august": 108,
    "aug": 108,
    "september": 109,
    "sep": 109,
    "oce": 110,
    "october": 110,
    "nov": 111,
    "november": 111,
    "dec": 112,
    "december": 112
]

let months = [
    
    "jan",
    "january",
    "feb",
    "february",
    "jan",
    "january",
    "jan",
    "january",
    "jan",
    "january",
    "jan",
    "january",
    "jan",
    "january",
    "jan",
    "january",
    "jan",
    "january",
    "jan",
    "january",

]

let DB_URL = "http://localhost:3000/"

func URLify(url: String) -> String! {
    return url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
}

var user_id = ""

var friendList:[String] = []
var friendId:[String: String] = [:]

var userReminders:[Reminder] = []

