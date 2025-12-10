//
//  UsageData.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import Foundation

// MARK: - JSONL Entry Models

struct ConversationEntry: Decodable {
    let type: String?
    let message: MessageContent?
    let timestamp: String?
    let sessionId: String?

    enum CodingKeys: String, CodingKey {
        case type
        case message
        case timestamp
        case sessionId
    }
}

struct MessageContent: Decodable {
    let role: String?
    let model: String?
    let usage: TokenUsage?
}

struct TokenUsage: Decodable {
    let inputTokens: Int?
    let outputTokens: Int?
    let cacheCreationInputTokens: Int?
    let cacheReadInputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheCreationInputTokens = "cache_creation_input_tokens"
        case cacheReadInputTokens = "cache_read_input_tokens"
    }

    var totalTokens: Int {
        (inputTokens ?? 0) + (outputTokens ?? 0) + (cacheCreationInputTokens ?? 0) + (cacheReadInputTokens ?? 0)
    }
}

// MARK: - Aggregated Usage for Display

struct UsageSummary: Equatable {
    let totalInputTokens: Int
    let totalOutputTokens: Int
    let totalCacheCreationTokens: Int
    let totalCacheReadTokens: Int
    let estimatedCost: Double
    let sessionCount: Int
    let messageCount: Int
    let firstTimestamp: Date?
    let lastUpdated: Date

    var totalTokens: Int {
        totalInputTokens + totalOutputTokens + totalCacheCreationTokens + totalCacheReadTokens
    }

    static let empty = UsageSummary(
        totalInputTokens: 0,
        totalOutputTokens: 0,
        totalCacheCreationTokens: 0,
        totalCacheReadTokens: 0,
        estimatedCost: 0,
        sessionCount: 0,
        messageCount: 0,
        firstTimestamp: nil,
        lastUpdated: Date()
    )

    static func + (lhs: UsageSummary, rhs: UsageSummary) -> UsageSummary {
        let earlierFirst: Date?
        if let lf = lhs.firstTimestamp, let rf = rhs.firstTimestamp {
            earlierFirst = min(lf, rf)
        } else {
            earlierFirst = lhs.firstTimestamp ?? rhs.firstTimestamp
        }

        return UsageSummary(
            totalInputTokens: lhs.totalInputTokens + rhs.totalInputTokens,
            totalOutputTokens: lhs.totalOutputTokens + rhs.totalOutputTokens,
            totalCacheCreationTokens: lhs.totalCacheCreationTokens + rhs.totalCacheCreationTokens,
            totalCacheReadTokens: lhs.totalCacheReadTokens + rhs.totalCacheReadTokens,
            estimatedCost: lhs.estimatedCost + rhs.estimatedCost,
            sessionCount: lhs.sessionCount + rhs.sessionCount,
            messageCount: lhs.messageCount + rhs.messageCount,
            firstTimestamp: earlierFirst,
            lastUpdated: max(lhs.lastUpdated, rhs.lastUpdated)
        )
    }
}

// MARK: - Model Pricing (per 1M tokens)

struct ModelPricing {
    let inputPricePerMillion: Double
    let outputPricePerMillion: Double
    let cacheCreationPricePerMillion: Double
    let cacheReadPricePerMillion: Double

    static let claude4Sonnet = ModelPricing(
        inputPricePerMillion: 3.0,
        outputPricePerMillion: 15.0,
        cacheCreationPricePerMillion: 3.75,
        cacheReadPricePerMillion: 0.30
    )

    static let claude4Haiku = ModelPricing(
        inputPricePerMillion: 0.25,
        outputPricePerMillion: 1.25,
        cacheCreationPricePerMillion: 0.30,
        cacheReadPricePerMillion: 0.03
    )

    static let claude4Opus = ModelPricing(
        inputPricePerMillion: 15.0,
        outputPricePerMillion: 75.0,
        cacheCreationPricePerMillion: 18.75,
        cacheReadPricePerMillion: 1.50
    )

    static let defaultPricing = claude4Sonnet

    static func pricing(for model: String?) -> ModelPricing {
        guard let model = model?.lowercased() else { return defaultPricing }

        if model.contains("opus") {
            return claude4Opus
        } else if model.contains("haiku") {
            return claude4Haiku
        } else {
            return claude4Sonnet
        }
    }

    func calculateCost(inputTokens: Int, outputTokens: Int, cacheCreationTokens: Int, cacheReadTokens: Int) -> Double {
        let inputCost = Double(inputTokens) / 1_000_000 * inputPricePerMillion
        let outputCost = Double(outputTokens) / 1_000_000 * outputPricePerMillion
        let cacheCreationCost = Double(cacheCreationTokens) / 1_000_000 * cacheCreationPricePerMillion
        let cacheReadCost = Double(cacheReadTokens) / 1_000_000 * cacheReadPricePerMillion

        return inputCost + outputCost + cacheCreationCost + cacheReadCost
    }
}
