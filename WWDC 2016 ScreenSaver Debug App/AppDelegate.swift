//
//  AppDelegate.swift
//  WWDC 2016 ScreenSaver
//
//  Created by Michał Kałużny on 19/06/16.
//  Copyright © 2016 Makowiec. All rights reserved.
//

import Cocoa
import ScreenSaver

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    let screenSaverView: ScreenSaverView? = nil
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        guard let bundleURL = Bundle.main().urlForResource("WWDC 2016 ScreenSaver", withExtension: "saver") else {
            return assertionFailure("Couldn't load screen saver bundle")
        }

        guard let screenSaverBundle = Bundle(url: bundleURL) else {
            return assertionFailure("Couldn't find a screen saver bundle")
        }

        guard let screenSaverClass = screenSaverBundle.principalClass as? ScreenSaverView.Type else {
            return assertionFailure("Couldn't find a principal class")
        }

        let screenSaverView = screenSaverClass.init(frame: CGRect(), isPreview: true)

        if let screenSaverView = screenSaverView {
            screenSaverView.frame = window.contentView!.bounds;
            window.contentView!.addSubview(screenSaverView);
        }
    }
    
}

