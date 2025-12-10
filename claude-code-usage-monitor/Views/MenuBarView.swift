//
//  MenuBarView.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import SwiftUI

struct MenuBarView: View {
    var settingsManager: SettingsManager
    var usageService: UsageService

    @Environment(\.openWindow) private var openWindow
    @State private var timer: Timer?

    var limits: PlanLimits {
        settingsManager.currentLimits
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerSection

            if usageService.isLoading && usageService.lastRefresh == nil {
                loadingView
            } else if let error = usageService.error {
                errorView(error)
            } else {
                usageContent
            }

            Divider()

            footerButtons
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            usageService.startMonitoring()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            if usageService.isActive {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.green)
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentColor)
            }
            Text("Claude Code Usage")
                .font(.headline)
            Spacer()
            if usageService.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
            } else {
                Button(action: {
                    Task { await usageService.refresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
            Text("Loading usage data...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("No Data")
                .font(.headline)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Usage Content

    private var usageContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Plan & Time remaining
            HStack {
                Text(settingsManager.selectedPlan.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(4)

                Spacer()

                if let window = usageService.currentWindow {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(formatTimeRemaining(window.timeRemaining))
                            .font(.caption)
                            .monospacedDigit()
                    }
                    .foregroundColor(.secondary)
                }
            }

            // Progress Bars
            if let window = usageService.currentWindow {
                VStack(spacing: 8) {
                    // Cost
                    CostProgressBar(
                        current: window.costUsage,
                        max: limits.costLimit
                    )

                    // Tokens
                    TokenProgressBar(
                        label: "Tokens",
                        current: window.tokenUsage,
                        max: limits.tokenLimit,
                        color: .blue
                    )

                    // Messages
                    TokenProgressBar(
                        label: "Messages",
                        current: window.messageCount,
                        max: limits.messageLimit,
                        color: .purple
                    )
                }
            }

            Divider()

            // Today's summary
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    StatItem(label: "Cost", value: formatCurrency(usageService.todayUsage.estimatedCost))
                    Spacer()
                    StatItem(label: "Tokens", value: formatTokens(usageService.todayUsage.totalTokens))
                    Spacer()
                    StatItem(label: "Sessions", value: "\(usageService.todayUsage.sessionCount)")
                }
            }

            // Status
            if let lastRefresh = usageService.lastRefresh {
                HStack {
                    if usageService.isActive {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Text("Updated \(lastRefresh, style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Footer

    private var footerButtons: some View {
        HStack {
            Button(action: { openWindow(id: "settings") }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Quit", systemImage: "power")
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
    }

    // MARK: - Helpers

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: settingsManager.refreshInterval, repeats: true) { _ in
            Task { await usageService.refresh() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatCurrency(_ value: Double) -> String {
        String(format: "$%.2f", value)
    }

    private func formatTokens(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1000 {
            return String(format: "%.1fK", Double(value) / 1000)
        }
        return "\(value)"
    }

    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
}

struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
