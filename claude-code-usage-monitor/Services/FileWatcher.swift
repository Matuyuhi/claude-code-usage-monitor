//
//  FileWatcher.swift
//  claude-code-usage-monitor
//
//  Created by matuyuhi on 2025/12/10.
//

import Foundation

actor FileWatcher {
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var isWatching = false
    private var onChange: (() async -> Void)?

    func startWatching(path: String, onChange: @escaping () async -> Void) {
        guard !isWatching else { return }

        self.onChange = onChange

        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            print("Failed to open directory for watching: \(path)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename, .extend],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            Task {
                await self?.handleChange()
            }
        }

        source.setCancelHandler { [weak self] in
            Task {
                await self?.cleanup()
            }
        }

        dispatchSource = source
        source.resume()
        isWatching = true
    }

    func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
        isWatching = false
    }

    private func handleChange() async {
        await onChange?()
    }

    private func cleanup() {
        if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    deinit {
        if fileDescriptor >= 0 {
            close(fileDescriptor)
        }
    }
}
