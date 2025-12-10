//
//  PlanLimits.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import Foundation

enum PlanType: String, CaseIterable {
    case pro = "Pro"
    case max5 = "Max 5"
    case max20 = "Max 20"
    case custom = "Custom"
}

struct PlanLimits {
    let tokenLimit: Int
    let costLimit: Double
    let messageLimit: Int

    static let pro = PlanLimits(tokenLimit: 19_000, costLimit: 18.0, messageLimit: 250)
    static let max5 = PlanLimits(tokenLimit: 88_000, costLimit: 35.0, messageLimit: 1_000)
    static let max20 = PlanLimits(tokenLimit: 220_000, costLimit: 140.0, messageLimit: 2_000)
    static let custom = PlanLimits(tokenLimit: 44_000, costLimit: 50.0, messageLimit: 250)

    static func limits(for plan: PlanType) -> PlanLimits {
        switch plan {
        case .pro: return .pro
        case .max5: return .max5
        case .max20: return .max20
        case .custom: return .custom
        }
    }
}

// Session window is 5 hours
struct SessionWindow {
    let startTime: Date
    let endTime: Date
    let tokenUsage: Int
    let costUsage: Double
    let messageCount: Int

    var timeRemaining: TimeInterval {
        max(0, endTime.timeIntervalSince(Date()))
    }

    var isActive: Bool {
        Date() < endTime
    }

    static let windowDuration: TimeInterval = 5 * 60 * 60 // 5 hours
}
