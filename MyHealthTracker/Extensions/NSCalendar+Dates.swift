//
//  NSCalendar+Dates.swift
//  MyHealthTracker
//
//  Created by Carlos Pages on 15/10/2016.
//  Copyright © 2016 CarlosPages. All rights reserved.
//

import Foundation

extension Calendar {
    /**
     Returns a tuple containing the start and end dates for the week that the
     specified date falls in.
     */
    func weekDatesForDate(_ date: Date) -> (start: Date, end: Date) {
        var interval: TimeInterval = 0
        var start: Date = Date()
        _ = dateInterval(of: .weekOfYear, start: &start, interval: &interval, for: date)
        let end = start.addingTimeInterval(interval)
        
        return (start as Date, end as Date)
    }
}
