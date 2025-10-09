//
//  NetworkMonitor.swift
//  AstroSvitla
//
//  Observable network status helper backed by NWPathMonitor.
//

import Combine
import Network

@MainActor
final class NetworkMonitor: ObservableObject {

    @Published private(set) var isConnected: Bool = true

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.astrosvitla.networkMonitor")

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
