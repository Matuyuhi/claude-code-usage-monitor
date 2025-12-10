//
//  SettingsView.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import SwiftUI

struct SettingsView: View {
    var settingsManager: SettingsManager
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var selectedPlan: PlanType = .max5

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button(action: { dismissWindow(id: "settings") }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            VStack(alignment: .leading, spacing: 16) {
                // Plan Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Your Plan")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Plan", selection: $selectedPlan) {
                        ForEach(PlanType.allCases, id: \.self) { plan in
                            Text(plan.rawValue).tag(plan)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Show limits for selected plan
                    let limits = PlanLimits.limits(for: selectedPlan)
                    VStack(alignment: .leading, spacing: 4) {
                        LimitInfoRow(icon: "dollarsign.circle", label: "Cost Limit", value: String(format: "$%.0f", limits.costLimit))
                        LimitInfoRow(icon: "number.circle", label: "Token Limit", value: formatTokens(limits.tokenLimit))
                        LimitInfoRow(icon: "message.circle", label: "Message Limit", value: "\(limits.messageLimit)")
                    }
                    .padding(.top, 8)
                }

                Divider()

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Claude Code uses a 5-hour rolling window for usage limits. The progress bars show your usage within the current window.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Spacer()

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("Cancel") {
                    dismissWindow(id: "settings")
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveSettings()
                    dismissWindow(id: "settings")
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 320, height: 340)
        .onAppear {
            selectedPlan = settingsManager.selectedPlan
        }
    }

    private func saveSettings() {
        settingsManager.selectedPlan = selectedPlan
        settingsManager.saveSettings()
    }

    private func formatTokens(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1000 {
            return String(format: "%.0fK", Double(value) / 1000)
        }
        return "\(value)"
    }
}

struct LimitInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
        }
        .font(.caption)
    }
}
