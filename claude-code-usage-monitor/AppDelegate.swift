//
//  AppDelegate.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar app
        NSApp.setActivationPolicy(.accessory)
    }
}
