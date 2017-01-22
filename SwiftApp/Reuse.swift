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
    "mar",
    "march",
    "apr",
    "april",
    "may",
    "jun",
    "june",
    "july",
    "jul",
    "aug",
    "august",
    "sep",
    "september",
    "oct",
    "october",
    "nov",
    "november",
    "dec",
    "december"

]

let monthsToNum = [
    
    "jan": 1,
    "january": 1,
    "feb": 2,
    "february": 2,
    "mar": 3,
    "march": 3,
    "apr":4,
    "april":4,
    "may":5,
    "jun":5,
    "june":6,
    "july": 7,
    "jul":7,
    "aug": 8,
    "august": 8,
    "sep": 9,
    "september":9,
    "oct":10,
    "october":11,
    "nov":11,
    "november":11,
    "dec":12,
    "december":12
    
]

let tm = [
    "am",
    "a.m",
    "pm",
    "p.m",
    "a m",
    "p m"
]

let DB_URL = "http://192.169.164.204:3000"

func URLify(url: String) -> String! {
    return url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
}

var user_id = ""

var friendList:[String] = []
var friendId:[String: String] = [:]

var userReminders:[Reminder] = []

