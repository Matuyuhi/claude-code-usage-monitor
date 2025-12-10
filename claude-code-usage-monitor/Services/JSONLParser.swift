//
//  JSONLParser.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import Foundation

actor JSONLParser {
    private let decoder = JSONDecoder()
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    func parseFile(at url: URL, since startDate: Date? = nil) -> UsageSummary {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else {
            return .empty
        }

        let lines = content.components(separatedBy: .newlines)
        var totalInput = 0
        var totalOutput = 0
        var totalCacheCreation = 0
        var totalCacheRead = 0
        var totalCost = 0.0
        var sessionIds = Set<String>()
        var messageCount = 0
        var firstTimestamp: Date?
        var latestTimestamp = Date.distantPast

        for line in lines {
            guard !line.isEmpty,
                  let lineData = line.data(using: .utf8) else { continue }

            do {
                let entry = try decoder.decode(ConversationEntry.self, from: lineData)

                // Only process assistant messages with usage data
                guard entry.type == "assistant",
                      let message = entry.message,
                      let usage = message.usage else { continue }

                // Parse timestamp
                var entryTimestamp: Date?
                if let timestampStr = entry.timestamp {
                    entryTimestamp = parseTimestamp(timestampStr)
                }

                // Filter by date if specified
                if let startDate = startDate,
                   let timestamp = entryTimestamp {
                    if timestamp < startDate {
                        continue
                    }
                }

                // Track first and latest timestamps
                if let timestamp = entryTimestamp {
                    if firstTimestamp == nil || timestamp < firstTimestamp! {
                        firstTimestamp = timestamp
                    }
                    if timestamp > latestTimestamp {
                        latestTimestamp = timestamp
                    }
                }

                // Track session
                if let sessionId = entry.sessionId {
                    sessionIds.insert(sessionId)
                }

                // Count this message
                messageCount += 1

                // Aggregate tokens
                let inputTokens = usage.inputTokens ?? 0
                let outputTokens = usage.outputTokens ?? 0
                let cacheCreationTokens = usage.cacheCreationInputTokens ?? 0
                let cacheReadTokens = usage.cacheReadInputTokens ?? 0

                totalInput += inputTokens
                totalOutput += outputTokens
                totalCacheCreation += cacheCreationTokens
                totalCacheRead += cacheReadTokens

                // Calculate cost based on model
                let pricing = ModelPricing.pricing(for: message.model)
                totalCost += pricing.calculateCost(
                    inputTokens: inputTokens,
                    outputTokens: outputTokens,
                    cacheCreationTokens: cacheCreationTokens,
                    cacheReadTokens: cacheReadTokens
                )
            } catch {
                // Skip malformed lines
                continue
            }
        }

        return UsageSummary(
            totalInputTokens: totalInput,
            totalOutputTokens: totalOutput,
            totalCacheCreationTokens: totalCacheCreation,
            totalCacheReadTokens: totalCacheRead,
            estimatedCost: totalCost,
            sessionCount: sessionIds.count,
            messageCount: messageCount,
            firstTimestamp: firstTimestamp,
            lastUpdated: latestTimestamp == Date.distantPast ? Date() : latestTimestamp
        )
    }

    private func parseTimestamp(_ string: String) -> Date? {
        // Try ISO8601 with fractional seconds
        if let date = dateFormatter.date(from: string) {
            return date
        }

        // Try without fractional seconds
        let simpleDateFormatter = ISO8601DateFormatter()
        simpleDateFormatter.formatOptions = [.withInternetDateTime]
        return simpleDateFormatter.date(from: string)
    }
}
