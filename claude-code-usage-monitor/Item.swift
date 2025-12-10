//
//  Item.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
