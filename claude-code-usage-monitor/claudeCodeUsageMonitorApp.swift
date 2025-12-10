//
//  claude_code_usage_monitorApp.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import SwiftUI

@main
struct claudeCodeUsageMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var settingsManager = SettingsManager.shared
    @State private var usageService = UsageService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(settingsManager: settingsManager, usageService: usageService)
        } label: {
            AnimatedMenuBarIcon(isActive: usageService.isActive)
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView(settingsManager: settingsManager)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 320, height: 340)
    }
}

struct AnimatedMenuBarIcon: View {
    let isActive: Bool
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        Image(systemName: iconName)
            .symbolEffect(.pulse, isActive: isActive)
    }

    private var iconName: String {
        if isActive {
            return "bolt.fill"
        } else {
            return "chart.bar.fill"
        }
    }
}
