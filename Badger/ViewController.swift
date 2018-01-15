//
//  ViewController.swift
//  Badger - Use the Badger class to display alerts and set the app icon badge in the background.
//
//  Created by ByteSlinger 2018-01-08.
//  Copyright © 2018 ByteSlinger. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

let ME = "Badger"

class ViewController: UIViewController, CLLocationManagerDelegate {
    private var timer: Timer! = nil
    private var counter = 0
    private var locationManager: CLLocationManager! = nil
    
    @objc var badger = Badger()
    
    @IBOutlet weak var enableSoundSwitch: UISwitch!
    @IBOutlet weak var enableUpdateSwitch: UISwitch!
    @IBOutlet weak var badgeValue: UILabel!     // placed on upper right of appIconImage in storyboard
    @IBOutlet weak var appIconImage: UIImageView!
    
    let SPEW_ON = false      // set this to true for debugging messages in console
    func spew(_ msg: String) {
        if (SPEW_ON) {
            print(msg)
        }
    }
    
    // connected  in Main.storyboard
    @IBAction func enableAlertSound(_ sender: UISwitch) {
        spew("enableAlertSound()")
        
        self.badger.enableSound = self.enableSoundSwitch.isOn
    }
    
    @IBAction func enableBadgeUpdate(_ sender: UISwitch) {
        spew("enableBadgeUpdate()")
        
        if (self.badger.isAuthorized()) {
            self.badger.enableUpdate = self.enableUpdateSwitch.isOn
        } else {
            self.enableUpdateSwitch.isOn = false
            self.badger.enableAlert = false
            self.badger.enableUpdate = false
            
            showAlert(badger.notAuthorizedMessage())
        }
        
        if (!self.enableUpdateSwitch.isOn) {
            self.counter = 0
        }
        
        updateDisplay()
    }
    
    // this is against the user interface guidelines, but it does work
    @objc func goToBackground() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        }
    }
    
    @objc func incrementCounter() {
        if (self.badger.isInTheBackground()) {
            spew("incrementCounter() - enableUpdateSwitch = \(self.badger.enableUpdate), background = \(self.badger.isInTheBackground())")
            
            if (self.badger.enableUpdate) {
                self.counter += 1
                
                self.badger.setBadge(self.counter)
            }
        }
    }
    
    override func viewDidLoad() {
        spew("viewWillDidLoad()")
        
        super.viewDidLoad()
        
        startLocationManager()  // allows app to run in the background
        
        // allow the user to go to the background with a button
        // (against user interface guidelines but a neat trick for this app...)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Go To Background", style: .done, target: self, action: #selector(goToBackground))
        
        // make my "badge" rounded like the app icon badge
        self.badgeValue.layer.cornerRadius = 20
        self.badgeValue.layer.masksToBounds = true
        
        // get the app icon image for my image (larger than the app icon)
        self.appIconImage.image = UIApplication.shared.icon
        self.appIconImage.layer.cornerRadius = 20
        self.appIconImage.layer.masksToBounds = true
        
        self.badger.enableSound = false
        self.badger.enableUpdate = false
        
        updateDisplay()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(incrementCounter), userInfo: nil, repeats:true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateDisplay), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    // start the location manager so we are kept alive in the background
    func startLocationManager() {
        if (CLLocationManager.locationServicesEnabled() == false ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied) {
            self.locationManager = nil
            
            showAlert("Location Services must be set to ON and set to ALWAYS for the \(ME) app " +
                "to be able to run in the background")
        } else {
            if (self.locationManager == nil) {
                // turn on LocationManager so we stay alive in the background
                self.locationManager = CLLocationManager()
                self.locationManager.requestAlwaysAuthorization()
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                self.locationManager.allowsBackgroundLocationUpdates = true     // the magic sauce...
                self.locationManager.pausesLocationUpdatesAutomatically = false
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    @objc func enableUpdate() {
        self.badger.enableUpdate = true
    }
    
    @objc func disableUpdate() {
        self.badger.enableUpdate = false
    }
    
    @objc func enableAlert() {
        self.badger.enableAlert = true
        
        updateDisplay()
    }
    
    @objc func disableAlert() {
        self.badger.enableAlert = false
        
        updateDisplay()
    }
    
    @objc func updateDisplay() {
        spew("updateDisplay()")
        
        if (self.locationManager == nil) {
            self.enableUpdateSwitch.isEnabled = false
        } else {
            self.enableUpdateSwitch.isEnabled = true
            
            if (self.badger.enableAlert) {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Disable Alerts",
                                                                    style: .done, target: self,
                                                                    action: #selector(disableAlert))
            } else {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Enable Alerts",
                                                                    style: .done, target: self,
                                                                    action: #selector(enableAlert))
            }
            
            self.enableUpdateSwitch.isOn = self.badger.enableUpdate
        }
        
        self.badgeValue.isHidden = self.counter==0 ? true : false
        
        self.badgeValue.text = "  \(self.counter)  "
    }
    
    // show a popup message
    func showAlert (_ message: String) {
        let alert = UIAlertController(
            title: "\(ME) Alert",
            message: message,
            preferredStyle: UIAlertControllerStyle.alert);
        
        let alertOKAction = UIAlertAction(title:"OK", style: UIAlertActionStyle.default,
                                          handler: { action in })
        
        alert.addAction(alertOKAction);
        
        self.present(alert, animated: true, completion: nil);
    }
}
