//
//  AppDelegate.swift
//  BumpCamera
//
//  Created by Stuart Rankin on 1/8/19.
//  Copyright © 2019 Stuart Rankin. All rights reserved.
//

import UIKit

@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    let _Settings = UserDefaults.standard
    var DidCrash = false
    var CrashedFilterName = ""
    var OnDebugger = false
    var Filters: FilterManager? = nil
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        
        #if DEBUG
        //See if we're running because of the debugger. We care about this because the developer can stop BumpCamera via Xcode
        //which to BumpCamera itself, looks like a crash. In order for this to work, the debug scheme for BumpCamera needs to
        //have the "debugger" environment variable created and set to "true" (both strings).
        let Env = ProcessInfo().environment
        if let DebugVal = Env["debugger"]
        {
            OnDebugger = DebugVal == "true"
        }
        #endif
        
        if _Settings.bool(forKey: "SettingsInstalled")
        {
            //Check for app crashes.
            if !_Settings.bool(forKey: "ClosedCleanly")
            {
                //For some reason, we crashed during the last session. On the assumption that a filter was to blame,
                //set the current filter as the PassThrough filter and make sure the filter manager doesn't try to
                //start with something else.
                let FilterIDOnCrash = UUID(uuidString: _Settings.string(forKey: "CurrentFilter")!)
                let FilterID = FilterManager.GetFilterID(For: .PassThrough)
                _Settings.set(FilterID?.uuidString, forKey: "CurrentFilter")
                let InitialGroupID = FilterManager.GetGroupID(ForGroup: .Standard)
                _Settings.set(InitialGroupID?.uuidString, forKey: "CurrentGroup")
                _Settings.set(false, forKey: "StartWithLastFilter")
                let PreviousFilterType = FilterManager.GetFilterTypeFrom(ID: FilterIDOnCrash!)
                CrashedFilterName = FilterManager.GetFilterTitle(PreviousFilterType!)!
                print("Last instantiation crashed. Filter was \(CrashedFilterName). Resetting filter to Pass Through and group to Standard.")
                DidCrash = true
            }
        }
        if OnDebugger
        {
            _Settings.set(true, forKey: "ClosedCleanly")
        }
        else
        {
            _Settings.set(false, forKey: "ClosedCleanly")
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("BumpCamera resigned active.")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("BumpCamera entered background.")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("BumpCamera will enter foreground.")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("BumpCamera became active.")
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("Setting closed cleanly flag.")
        ActivityLog.Close()
        _Settings.set(true, forKey: "ClosedCleanly")
    }
}

