//
//  Badger.swift
//  Badger - Display background notification alert and set App Icon Badge while in the background.
//
//  Created by ByteSlinger on 2018-01-12.
//  Copyright © 2018 ByteSlinger. All rights reserved.
//

import UIKit
import UserNotifications

class Badger: NSObject, UNUserNotificationCenterDelegate {
    private let ME = "Badger"   // Honey Badger don't care...

    private static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") ?? "App?"
    private var authorized = false
    private var updateTimer: Timer! = nil
    private var badge = 0
    private var inTheBackground = false
    private var title: String? = "Alert"
    private var subTitle: String? = nil
    private var body: String? = "\(Badger.appName) is running in the background."

    // caller can get/set these
    public var DEBUG = false        // set this to true for debugging messages in console
    public var enableAlert = true
    public var enableUpdate = true
    public var enableSound = true  // can be annoying while background testing
    public var updateFrequency = 1  // update once a second

    func spew(_ msg: String) {
        if (DEBUG) {
            print(msg)
        }
    }
    
    public func notAuthorizedMessage() -> String {
        return "Allow Notifications for the \(Badger.appName) app have been turned OFF in Settings. " +
        "You must turn it ON for the \(Badger.appName) app to function."
    }
    
    public func isInTheBackground() -> Bool {
        return inTheBackground
    }
    
    public func setTitle(_ stuff: String) {
        self.title = stuff
    }
    
    public func setSubTitle(_ stuff: String) {
        self.subTitle = stuff
    }
    
    public func setBody(_ stuff: String) {
        self.body = stuff
    }
    
    override init() {
        super.init()
        
        spew("\(ME).init() - appName = \(Badger.appName)")
        
        self.requestNoficationAuthorization()

        // setup my app observers to handle moving between foreground and background (and terminating)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: .UIApplicationWillTerminate, object: nil)
    
        clearBadge()   // initially set to 0, which clears it
    }
    
    // MARK:  - observer functions
    
    // when the app goes into the background, start updating the badge
    @objc func willResignActive() {
        spew("\(ME).willResignActive()")
        
        self.inTheBackground = true
        
        clearBadge()
        
        if (self.isAuthorized()) {
            if (self.enableAlert) {
                notify()                // send an alert to whatever is in the foreground
            }
            
            if (self.enableUpdate) {
                startBadgeUpdate()      // start setting the app icon badge
            }
        }
    }
    
    // when the app is coming into the foreground, cancel the badge updates
    @objc func willEnterForeground() {
        spew("\(ME).willEnterForeground()")
        
        self.inTheBackground = false
        
        cancelBadgeUpdate()
        
        clearBadge()
    }
    
    // when the app terminates, clear the badge
    @objc func willTerminate() {
        spew("\(ME).willTerminate()")
        
        cancelAlerts()
        
        cancelBadgeUpdate()
    }
        
    // MARK: - badge handling functions
    
    public func getBadge() -> Int {
        return self.badge
    }
    
    // the caller should set this as often as needed
    public func setBadge(_ badge: Int) {
        spew("\(ME).setBadge() - badge = \(badge)")
        
        self.badge = badge
    }
    
    // TODO:  setting/clearing the badge does NOT work when the app is terminated
    public func clearBadge() {
        spew("\(ME).clearBadge()")
        
        setBadge(0)
        
        updateBadge()
    }
    
    @objc public func updateBadge() {
        spew("\(ME).updateBadge() - badge = \(self.badge)")
        
        UIApplication.shared.applicationIconBadgeNumber = self.badge
    }
    
    // use a timer to increment and set the app icon badge
    func startBadgeUpdate() {
        spew("\(ME).startBadgeUpdate()")
        
        // just incase the timer was left running
        if (self.updateTimer != nil) {
            self.updateTimer!.invalidate()
            self.updateTimer = nil
        }
        
        self.updateTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.updateFrequency),
                                                target: self, selector: #selector(updateBadge), userInfo: nil, repeats:true)
    }
    
    func cancelBadgeUpdate() {
        spew("\(ME).cancelBadgeUpdate()")
        
        if (self.updateTimer != nil) {
            self.updateTimer!.invalidate()
        }
    }
        
    // MARK:  - notification handling functions
    
    func isAuthorized() -> Bool {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if (settings.authorizationStatus != .authorized) {
                self.authorized = false
            } else {
                self.authorized = true
            }
        }
        
        spew("\(ME).isAuthorized() = \(self.authorized)")

        return self.authorized
    }
    
    func requestNoficationAuthorization() {
        spew("\(ME).requestNoficationAuthorization()")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if (granted) {
                self.authorized = true
                
                self.registerCategories()
            } else {
                self.spew("\(self.ME).requestNoficationAuthorization() failed!")
            }
        }
    }
    
    func cancelAlerts() {
        spew("\(ME).cancelAlerts()")
        
        // incase there is an alert lurking out there, remove them all
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [UUID().uuidString])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [UUID().uuidString])
    }
        
    // setup notification "buttons"
    func registerCategories() {
        spew("\(ME).registerCategories()")
        
        let center = UNUserNotificationCenter.current()
        
        center.delegate = self
        
        let open = UNNotificationAction(identifier: "open", title: "Open \(Badger.appName) app…", options: .foreground)
        let disable = UNNotificationAction(identifier: "disable", title: "Disable This Alert", options: .destructive)
        let category = UNNotificationCategory(identifier: "alert", actions: [open,disable], intentIdentifiers: [])
        
        center.setNotificationCategories([category])
    }
        
    // send a notification request
    func notify() {
        if (self.isAuthorized() && self.enableAlert) {
            
            spew("\(ME).notify()")
            
            //cancelAlerts()  // any existing alerts
            
            //let onOffMsg = self.badgeEnabled ? "On" : "Off"
            let center = UNUserNotificationCenter.current()
            
            let content = UNMutableNotificationContent()
            
            // NOTE:  one of title, subtitle or body is required in 11.x, 10.x requires body
            if (self.title != nil) {
                content.title = self.title!
            }
            if (self.subTitle != nil) {
                content.subtitle = self.subTitle!
            }
            if (self.body != nil) {
                content.body = self.body!
            }
            content.categoryIdentifier = "alert"
            content.userInfo = ["customData": "notify"]
            if (self.enableSound) {
                content.sound = UNNotificationSound.default()
            }
            content.badge = self.badge as NSNumber
            
            if let attachment = UNNotificationAttachment.create(identifier: UIApplication.shared.uniqueId,
                                                                image: UIApplication.shared.icon!, options: nil) {
                content.attachments = [attachment]
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            center.add(request)
        }
    }
        
    // UNNotificationCenterDelegate method
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // pull out the buried userInfo dictionary
        let userInfo = response.notification.request.content.userInfo
        
        if let customData = userInfo["customData"] as? String {
            spew("\(ME).userNotificationCenter.didReceive() - received: \(customData), actionId: \(response.actionIdentifier)")
            
            switch response.actionIdentifier {
            case UNNotificationDefaultActionIdentifier:
                // the user swiped to unlock
                spew("User swipe or tap...")
                
            case "show":
                // the user tapped our "Open the APP app…" bit
                spew("Open the app…")
                
            case "disable":
                spew("User disabled alerts...")
                self.enableAlert = false
                
            default:
                break
            }
        }
        
        // you must call the completion handler when you're done
        completionHandler()
    }
}
