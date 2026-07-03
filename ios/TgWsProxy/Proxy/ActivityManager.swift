import ActivityKit
import Foundation
import WidgetKit

@MainActor
enum ActivityManager {
#if TGWS_LIVE_ACTIVITY_AVAILABLE
    private static var activity: Activity<ProxyActivityAttributes>?
    private static var lastWidgetReload: Date = .distantPast
    private static let widgetReloadInterval: TimeInterval = 15

    static func started(mode: String) {
        WidgetStatusStore.update(connected: true)
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadControls(ofKind: "TgWsProxy.Control")
        }

        guard UserDefaults.standard.object(forKey: "app.liveActivities") as? Bool ?? true else {
            endAll()
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if let existing = Activity<ProxyActivityAttributes>.activities.first {
            activity = existing
            return
        }
        let attributes = ProxyActivityAttributes(mode: mode)
        let state = ProxyActivityAttributes.ContentState(
            connected: true,
            upload: "0 B",
            download: "0 B",
            active: "0"
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            fputs("ActivityKit: started \(activity?.id ?? "unknown")\n", stderr)
        } catch {
            fputs("ActivityKit ERROR: \(error.localizedDescription)\n", stderr)
        }
    }

    static func update(stats: ProxyStats) {
        WidgetStatusStore.update(
            connected: true,
            upload: stats.uploaded,
            download: stats.downloaded,
            active: stats.active
        )
        if Date().timeIntervalSince(lastWidgetReload) >= widgetReloadInterval {
            lastWidgetReload = Date()
            WidgetCenter.shared.reloadAllTimelines()
        }
        guard UserDefaults.standard.object(forKey: "app.liveActivities") as? Bool ?? true else {
            endAll()
            return
        }
        let state = ProxyActivityAttributes.ContentState(
            connected: true,
            upload: stats.uploaded,
            download: stats.downloaded,
            active: stats.active
        )
        Task {
            await activity?.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    static func stopped() {
        WidgetStatusStore.update(connected: false)
        WidgetCenter.shared.reloadAllTimelines()
        if #available(iOS 18.0, *) {
            ControlCenter.shared.reloadControls(ofKind: "TgWsProxy.Control")
        }
        endAll()
    }

    static func setEnabled(_ enabled: Bool, mode: String, running: Bool) {
        if enabled, running {
            started(mode: mode)
        } else if !enabled {
            endAll()
        }
    }

    private static func endAll() {
        let state = ProxyActivityAttributes.ContentState(
            connected: false,
            upload: "0 B",
            download: "0 B",
            active: "0"
        )
        Task {
            for item in Activity<ProxyActivityAttributes>.activities {
                await item.end(
                    ActivityContent(state: state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
            activity = nil
        }
    }
#else
    static func started(mode: String) {}
    static func update(stats: ProxyStats) {}
    static func stopped() {}
    static func setEnabled(_ enabled: Bool, mode: String, running: Bool) {}
#endif
}
