//
//  String+Dates.swift
//  FP
//
//  Created by Bajrang on 18/08/18.
//  Copyright © 2017 Bajrang. All rights reserved.
//

import UIKit

extension String {
	func date(withFormat format: String = "yyyy-MM-dd") -> Date? {
		let formatter = DateFormatter()
		formatter.dateFormat = format
        formatter.timeZone = TimeZone.current
		return formatter.date(from: self)
	}
}

extension Date {
    
    func toString(withFormat format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    func dateStringWithTime(withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    
    func timestampToStringDate() -> String
    {
        //dd MMM, YYYY
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "MM/dd/YYYY"
        
        let dateString = dayTimePeriodFormatter.string(from: self)
        
        return dateString
    }
    
    func timestampToStringTime(format: String = "h:mm a", timestamp: Double?) -> String
    {
        var date = self
        if timestamp != nil
        {
            date = Date(timeIntervalSince1970: timestamp! / 1000.0)
        }
        
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = format
        
        let dateString = dayTimePeriodFormatter.string(from: date)
        return dateString
    }
    
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        
        let currentCalendar = Calendar.current
        
        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
        
        return end - start
    }
    
}
