//
//  claude_code_usage_monitorApp.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import SwiftUI
import SwiftData

@main
struct claudeCodeUsageMonitorApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
