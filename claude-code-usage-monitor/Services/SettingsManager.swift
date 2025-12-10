//
//  SettingsManager.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import Foundation
import Observation

@Observable
class SettingsManager {
    static let shared = SettingsManager()

    var refreshInterval: TimeInterval = 300
    var selectedPlan: PlanType = .max5

    private let refreshIntervalKey = "refreshInterval"
    private let selectedPlanKey = "selectedPlan"

    var currentLimits: PlanLimits {
        PlanLimits.limits(for: selectedPlan)
    }

    init() {
        loadSettings()
    }

    func loadSettings() {
        let defaults = UserDefaults.standard

        refreshInterval = defaults.double(forKey: refreshIntervalKey)
        if refreshInterval == 0 { refreshInterval = 300 }

        if let planRaw = defaults.string(forKey: selectedPlanKey),
           let plan = PlanType(rawValue: planRaw) {
            selectedPlan = plan
        }
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(refreshInterval, forKey: refreshIntervalKey)
        defaults.set(selectedPlan.rawValue, forKey: selectedPlanKey)
    }
}
