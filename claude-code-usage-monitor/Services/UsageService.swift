//
//  UsageService.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import Foundation
import Observation

@Observable
class UsageService {
    var todayUsage: UsageSummary = .empty
    var thisWeekUsage: UsageSummary = .empty
    var thisMonthUsage: UsageSummary = .empty
    var currentWindow: SessionWindow?
    var isLoading = false
    var error: String?
    var lastRefresh: Date?
    var isActive = false

    private let parser = JSONLParser()
    private var fileWatcher: FileWatcher?
    private var refreshTask: Task<Void, Never>?
    private var activityCheckTask: Task<Void, Never>?

    private var claudeDirectories: [URL] {
        let home = NSHomeDirectory()
        return [
            URL(fileURLWithPath: home).appendingPathComponent(".claude/projects"),
            URL(fileURLWithPath: home).appendingPathComponent(".config/claude/projects")
        ]
    }

    func startMonitoring() {
        Task {
            await refresh()
            await startFileWatching()
            startActivityCheck()
        }
    }

    func stopMonitoring() {
        refreshTask?.cancel()
        activityCheckTask?.cancel()
        Task {
            await fileWatcher?.stopWatching()
        }
    }

    func refresh() async {
        isLoading = true
        error = nil

        let calendar = Calendar.current
        let now = Date()

        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let jsonlFiles = findJSONLFiles()

        if jsonlFiles.isEmpty {
            error = "No Claude Code data found."
            isLoading = false
            return
        }

        var todayTotal = UsageSummary.empty
        var weekTotal = UsageSummary.empty
        var monthTotal = UsageSummary.empty

        for fileURL in jsonlFiles {
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                  let modDate = attrs[.modificationDate] as? Date else { continue }

            if modDate < monthStart { continue }

            let monthUsage = await parser.parseFile(at: fileURL, since: monthStart)
            monthTotal = monthTotal + monthUsage

            let weekUsage = await parser.parseFile(at: fileURL, since: weekStart)
            weekTotal = weekTotal + weekUsage

            let dayUsage = await parser.parseFile(at: fileURL, since: todayStart)
            todayTotal = todayTotal + dayUsage
        }

        todayUsage = todayTotal
        thisWeekUsage = weekTotal
        thisMonthUsage = monthTotal

        // Calculate session window based on first message timestamp
        // Session block = first message time + 5 hours
        currentWindow = calculateSessionWindow(from: todayTotal, now: now)

        lastRefresh = Date()
        isLoading = false
        checkActivity()
    }

    private func calculateSessionWindow(from usage: UsageSummary, now: Date) -> SessionWindow? {
        guard let firstTimestamp = usage.firstTimestamp else {
            return nil
        }

        // Round to the hour (like claude-monitor does)
        let calendar = Calendar.current
        let roundedStart = calendar.date(bySetting: .minute, value: 0, of: firstTimestamp) ?? firstTimestamp

        let blockEnd = roundedStart.addingTimeInterval(SessionWindow.windowDuration)

        // If block has expired and there's recent activity, start new block from last message
        if blockEnd < now {
            // Block expired - calculate new block from most recent activity
            let lastActivity = usage.lastUpdated
            let newStart = calendar.date(bySetting: .minute, value: 0, of: lastActivity) ?? lastActivity
            let newEnd = newStart.addingTimeInterval(SessionWindow.windowDuration)

            // Re-calculate usage for this new window
            // For simplicity, use the existing totals (will be more accurate with more parsing)
            return SessionWindow(
                startTime: newStart,
                endTime: newEnd,
                tokenUsage: usage.totalTokens,
                costUsage: usage.estimatedCost,
                messageCount: usage.messageCount
            )
        }

        return SessionWindow(
            startTime: roundedStart,
            endTime: blockEnd,
            tokenUsage: usage.totalTokens,
            costUsage: usage.estimatedCost,
            messageCount: usage.messageCount
        )
    }

    private func findJSONLFiles() -> [URL] {
        var files: [URL] = []
        let fileManager = FileManager.default

        for baseDir in claudeDirectories {
            guard fileManager.fileExists(atPath: baseDir.path) else { continue }

            guard let projectDirs = try? fileManager.contentsOfDirectory(
                at: baseDir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: []
            ) else { continue }

            for projectDir in projectDirs {
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: projectDir.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else { continue }

                guard let projectFiles = try? fileManager.contentsOfDirectory(
                    at: projectDir,
                    includingPropertiesForKeys: [.contentModificationDateKey],
                    options: []
                ) else { continue }

                for file in projectFiles {
                    if file.pathExtension == "jsonl" {
                        files.append(file)
                    }
                }
            }
        }

        return files
    }

    private func startFileWatching() async {
        fileWatcher = FileWatcher()

        for baseDir in claudeDirectories {
            let path = baseDir.path
            guard FileManager.default.fileExists(atPath: path) else { continue }

            await fileWatcher?.startWatching(path: path) { [weak self] in
                await MainActor.run { self?.isActive = true }
                await self?.debounceRefresh()
            }
        }
    }

    private func startActivityCheck() {
        activityCheckTask?.cancel()
        activityCheckTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { break }
                checkActivity()
            }
        }
    }

    private func checkActivity() {
        let jsonlFiles = findJSONLFiles()
        let now = Date()
        var recentlyModified = false

        for fileURL in jsonlFiles {
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                  let modDate = attrs[.modificationDate] as? Date else { continue }

            if now.timeIntervalSince(modDate) < 30 {
                recentlyModified = true
                break
            }
        }

        isActive = recentlyModified
    }

    private func debounceRefresh() async {
        refreshTask?.cancel()
        refreshTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }
}
