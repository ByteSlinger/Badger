# Badger App
This is a sample iOS Swift(4) app for Local Notifications and setting the App Icon Badge in the background.

Here are the screenshots from the app:

<img src="https://user-images.githubusercontent.com/2251646/34843616-c875681a-f6c3-11e7-9835-d90ff8c2a0b9.png" />

## Overview
For a GPS/Location Services app that I have released, I needed to warn the user that the app was running in the background.  Apps that use the GPS seriously drain the battery.  I wanted a way to warn the user WHILE the app is in the background, that it is still running so the user can return to the app or terminate it.

As an experiment, I wrote the Badger App to figure out a good way to achieve this that would work well for my GPS/Location Services app.

When the Badger App goes into the background (user presses Home button), it displays a Local Notification, which appears on the home screen or on top of whatever app the user brings to the foreground.  Then in the background, Badger uses a 1 second timer to increment and update the Badger App Icon Badge.

## Prerequisites

You will need the following to build and run this app:

* Apple Macintosh computer
* Xcode application installed and configured (I used Version 9.2)
* Copy of this repository (click "Clone or Download" on main page) [GitHub repo](https://github.com/ByteSlinger/Badger.git)

## Build and Deployment

I selected my iPhones to build and deploy to.  I did not try to test in the Xcode simulator.

* iPhone 5 - iOS Version 10.3.3
* iPhone 6+ - iOS Version 11.2.1
* Xcode deployment target - 10.3 (so the app would run on my old iPhone 5...)

## Tricks
There are several "tricks" necessary for the Badger App to work.  I spelunked in [Stack Overflow](http://stackoverflow.com) to solve some of them, others I developed myself over time:

[Extensions.swift](./Extensions.swift) - the "Swifty" way
* Return the app icon image
* Create a Notification Attachment containing an image (... the app icon image ...)

[ViewController.swift](./ViewController.swift) - everything is done in here
* Running in the background (see startLocationManager() function)
* Handling foreground/background transitions (NotificationCenter observers - see viewDidLoad() function)
* Go to background (save wear and tear on my home buttons (see goToBackground() function)
* Set and Clear the App Icon Badge (UIApplication.shared.applicationIconBadgeNumber variable)
* Run background function with a Timer (see startBadgeUpdate() function)
* Local Notifications (see requestNoficationAuthorization() and notify() functions)
* Display simple alert popup (see showAlert() function)

[Info.plist](./Info.plist)

There are a few things required in the Info.plist file to get the location services working properly on the iPhone 5 and the iPhone 6+:

* NSLocationWhenInUseUsageDescription - Message to user
* NSLocationAlwaysUsageDescription - Message to user
* NSLocationAlwaysAndWhenInUseUsageDescription - Message to user
* UIBackgroundModes - **location**
* UIRequiredDeviceCapabilities - armv7, **location-services** (NOTE:  **gps** was not necessary...)

## Bugs

I could not figure out a way to consistently clear the App Icon Badge when the app terminates.  If the app was in the foreground it often does work, but if the app is in the background, it very rarely works.  I posted a question on StackOverflow.com and the response was that it's not possible.  I tried several different approaches.  The appWillTerminate functionality does not seem to allow you to set the appIconBadge variable to 0 (zero) before the app terminates.  You can try, but it does not work.

## Author

* [ByteSlinger](https://github.com/ByteSlinger)

## License

This project is licensed under the MIT License:

Copyright 2018, ByteSlinger

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Acknowledgments

* Apple Human Interface Guidelines - [Notifications And Badging](https://developer.apple.com/carekit/human-interface-guidelines/user-interaction/notifications-and-badging/)
* HackingWithSwift.com - the best clues were here - [Local Notification Tutorial](https://www.hackingwithswift.com/read/21/overview)
