import AppIntents
import Foundation

extension Notification.Name {
    static let proxyCommand = Notification.Name("tgws.proxy.command")
}

enum ProxyCommandCenter {
    private static let key = "proxy.pendingCommand"

    static func submit(_ command: ProxyCommand) {
        UserDefaults.standard.set(command.rawValue, forKey: key)
        UserDefaults(suiteName: WidgetStatusStore.suiteName)?.set(command.rawValue, forKey: key)
        NotificationCenter.default.post(name: .proxyCommand, object: nil)
    }

    @MainActor
    static func consume(using proxy: ProxyViewModel) {
        let groupDefaults = UserDefaults(suiteName: WidgetStatusStore.suiteName)
        let raw = UserDefaults.standard.string(forKey: key)
            ?? groupDefaults?.string(forKey: key)
        guard let raw, let command = ProxyCommand(rawValue: raw) else { return }

        UserDefaults.standard.removeObject(forKey: key)
        groupDefaults?.removeObject(forKey: key)
        switch command {
        case .start:
            if !proxy.isRunning { proxy.start() }
        case .stop:
            if proxy.state != .stopped { proxy.stop() }
        }
    }
}

struct StartProxyIntent: AppIntent {
    static let title: LocalizedStringResource = "Запустить TG WS Proxy"
    static let description = IntentDescription("Открывает приложение и запускает локальный прокси.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        ProxyCommandCenter.submit(.start)
        return .result(dialog: "Запускаю TG WS Proxy")
    }
}

struct StopProxyIntent: AppIntent {
    static let title: LocalizedStringResource = "Остановить TG WS Proxy"
    static let description = IntentDescription("Открывает приложение и останавливает прокси.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        ProxyCommandCenter.submit(.stop)
        return .result(dialog: "Останавливаю TG WS Proxy")
    }
}

struct TgWsProxyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartProxyIntent(),
            phrases: [
                "Запустить прокси в \(.applicationName)",
                "Включить \(.applicationName)"
            ],
            shortTitle: "Запустить прокси",
            systemImageName: "play.circle.fill"
        )
        AppShortcut(
            intent: StopProxyIntent(),
            phrases: [
                "Остановить прокси в \(.applicationName)",
                "Выключить \(.applicationName)"
            ],
            shortTitle: "Остановить прокси",
            systemImageName: "stop.circle.fill"
        )
    }
}
