//
//  BackgroundRefreshScheduler.swift
//  nightguard WatchKit Extension
//
//  Created by Florian Preknya on 3/16/18.
//  Copyright © 2018 private. All rights reserved.
//

import Foundation
import WatchKit

/// This class is responsible with scheduling the next background refreshes. It will trigger a
/// background refresh as configured by the refreshRate property, the exact refresh moment will
/// be determined by dividing the hour in periods (starting from 0 minutes -> 60 minutes), the most apropiate
/// period start will be the next scheduled value.
///
/// For example, if the refresh rate is 15 (minutes), the scheduled times will be xx:00, xx:15, xx:30 and xx:45.
/// If calling schedule() at xx:18, the next refresh will be scheduled at xx:30. NOTE that watchOS can delay (or
/// even skip!) calling the WKExtensionDelegate.handle(_) method on scheduled time (the delay can be from seconds
/// to some minutes).
@available(watchOSApplicationExtension 3.0, *)
class BackgroundRefreshScheduler {
    
    static let instance = BackgroundRefreshScheduler()
    
    private let refreshRate: Int = BackgroundRefreshSettings.backgroundTaskScheduleRate
    private var lastScheduledTime: Date?
    
    private init() {
    }
    
    func schedule() {
        
        guard BackgroundRefreshSettings.enableBackgroundTasks else {
            print("Background tasks are disabled!")
            return
        }
        
        // obtain the refresh time
        let scheduleTime = nextScheduleTime(refreshRate: self.refreshRate)
        
        // log ONLY once
        let logRefreshTime = self.lastScheduledTime != scheduleTime
        self.lastScheduledTime = scheduleTime
        
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: scheduleTime, userInfo: nil) { (error: Error?) in
            
            if logRefreshTime {
                BackgroundRefreshLogger.info("Scheduled next background refresh at \(self.formatted(scheduleTime: scheduleTime))")
            }
            
            if let error = error {
                BackgroundRefreshLogger.info("Error occurred while scheduling background refresh: \(error.localizedDescription)")
            }
        }
    }
    
    private func nextScheduleTime(refreshRate: Int) -> Date {
        
        let now = Date()
        let unitFlags:Set<Calendar.Component> = [
            .hour, .day, .month,
            .year,.minute,.hour,.second,
            .calendar]
        var dateComponents = Calendar.current.dateComponents(unitFlags, from: now)
        
        // reset second
        dateComponents.second = 0
        
        let nextRefreshMinute = ((dateComponents.minute! / refreshRate) + 1) * refreshRate
        dateComponents.minute = nextRefreshMinute % 60
        
        var scheduleTime = Calendar.current.date(from: dateComponents)!
        if nextRefreshMinute >= 60 {
            scheduleTime = Calendar.current.date(byAdding: .hour, value: 1, to: scheduleTime)!
        }
        
        return scheduleTime
    }
    
    private func formatted(scheduleTime: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: scheduleTime)
    }
}
