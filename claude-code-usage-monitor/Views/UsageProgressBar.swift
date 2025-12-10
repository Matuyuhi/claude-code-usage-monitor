//
//  UsageProgressBar.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import SwiftUI

struct UsageProgressBar: View {
    let label: String
    let current: Double
    let max: Double
    let formatValue: (Double) -> String
    var color: Color = .accentColor
    var showPercentage: Bool = true

    private var progress: Double {
        guard max > 0 else { return 0 }
        return min(current / max, 1.0)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    private var barColor: Color {
        if progress >= 0.9 {
            return .red
        } else if progress >= 0.7 {
            return .orange
        } else {
            return color
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if showPercentage {
                    Text("\(percentage)%")
                        .font(.caption2)
                        .foregroundColor(progress >= 0.9 ? .red : .secondary)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text(formatValue(current))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                Spacer()
                Text("/ \(formatValue(max))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CostProgressBar: View {
    let current: Double
    let max: Double

    var body: some View {
        UsageProgressBar(
            label: "Cost",
            current: current,
            max: max,
            formatValue: { value in
                String(format: "$%.2f", value)
            },
            color: .green
        )
    }
}

struct TokenProgressBar: View {
    let label: String
    let current: Int
    let max: Int
    var color: Color = .blue

    var body: some View {
        UsageProgressBar(
            label: label,
            current: Double(current),
            max: Double(max),
            formatValue: { value in
                formatTokens(Int(value))
            },
            color: color
        )
    }

    private func formatTokens(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        } else if value >= 1000 {
            return String(format: "%.1fK", Double(value) / 1000)
        }
        return "\(value)"
    }
}

#Preview {
    VStack(spacing: 16) {
        CostProgressBar(current: 45.50, max: 100.0)
        TokenProgressBar(label: "Input", current: 2_500_000, max: 5_000_000, color: .blue)
        TokenProgressBar(label: "Output", current: 1_800_000, max: 2_000_000, color: .purple)
    }
    .padding()
    .frame(width: 300)
}
