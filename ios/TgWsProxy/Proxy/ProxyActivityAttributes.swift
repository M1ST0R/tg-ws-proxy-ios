import ActivityKit
import Foundation

enum ProxyCommand: String {
    case start
    case stop
}

struct ProxyActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var connected: Bool
        var upload: String
        var download: String
        var active: String
    }

    var mode: String
}

enum WidgetStatusStore {
    static let suiteName = "group.com.delewer.tgwsproxy"
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static var connected: Bool { defaults.bool(forKey: "widget.connected") }
    static var upload: String { defaults.string(forKey: "widget.upload") ?? "0 B" }
    static var download: String { defaults.string(forKey: "widget.download") ?? "0 B" }
    static var active: String { defaults.string(forKey: "widget.active") ?? "0" }

    static func update(
        connected: Bool,
        upload: String = "0 B",
        download: String = "0 B",
        active: String = "0"
    ) {
        defaults.set(connected, forKey: "widget.connected")
        defaults.set(upload, forKey: "widget.upload")
        defaults.set(download, forKey: "widget.download")
        defaults.set(active, forKey: "widget.active")
        defaults.set(Date(), forKey: "widget.updatedAt")
    }
}
