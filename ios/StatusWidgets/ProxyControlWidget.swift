import AppIntents
import SwiftUI
import WidgetKit

struct WidgetProxyCommandIntent: AppIntent {
    static let title: LocalizedStringResource = "Переключить TG WS Proxy"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        submit(WidgetStatusStore.connected ? .stop : .start)
        return .result()
    }

    private func submit(_ command: ProxyCommand) {
        let defaults = UserDefaults(suiteName: WidgetStatusStore.suiteName) ?? .standard
        defaults.set(command.rawValue, forKey: "proxy.pendingCommand")
    }
}

@available(iOSApplicationExtension 18.0, *)
struct SetProxyEnabledIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Включить TG WS Proxy"
    static let openAppWhenRun = true
    @Parameter(title: "Включено")
    var value: Bool

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: WidgetStatusStore.suiteName) ?? .standard
        defaults.set(value ? ProxyCommand.start.rawValue : ProxyCommand.stop.rawValue, forKey: "proxy.pendingCommand")
        return .result()
    }
}

@available(iOSApplicationExtension 18.0, *)
struct ProxyControlValueProvider: ControlValueProvider {
    let previewValue = false

    func currentValue() async throws -> Bool {
        WidgetStatusStore.connected
    }
}

@available(iOSApplicationExtension 18.0, *)
struct ProxyControlWidget: ControlWidget {
    let kind = "TgWsProxy.Control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: kind, provider: ProxyControlValueProvider()) { isOn in
            ControlWidgetToggle(isOn: isOn, action: SetProxyEnabledIntent()) {
                Label("TG WS Proxy", systemImage: isOn ? "paperplane.fill" : "paperplane")
            } valueLabel: { enabled in
                Text(enabled ? "Включён" : "Выключен")
            }
        }
        .displayName("TG WS Proxy")
        .description("Быстро запустить или остановить прокси.")
    }
}
