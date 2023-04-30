//
//  main.swift
//  DarkWallpaperHelper
//
//  Created by content on 2022/12/11.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    // Bundle Identifier of MainApplication target
    let mainBundleID = Bundle.main.bundleIdentifier!.replacingOccurrences(of: "Helper", with: "")
    let bundlePath = Bundle.main.bundlePath as NSString
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        guard NSRunningApplication.runningApplications(withBundleIdentifier: mainBundleID).isEmpty else {
            return NSApp.terminate(self)
        }

        let pathComponents = bundlePath.pathComponents
        let path = NSString.path(withComponents: Array(pathComponents[0 ..< (pathComponents.count - 4)]))
        
        let pathURL = URL(fileURLWithPath: path)
        
        NSWorkspace.shared.openApplication(at: pathURL,
                                            configuration: NSWorkspace.OpenConfiguration(),
                                           completionHandler: {(app, err) in
            if app == nil {
                let alert = NSAlert()
                alert.messageText = "Failed to open \(pathURL)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            NSApp.terminate(nil)
        })
    }

    func applicationWillTerminate(_ aNotification: Notification) {}
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
