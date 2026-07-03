import Foundation
import UIKit

enum DeepLinkDestination {
    case home
    case settings
    case logs
    case info
}

struct DeepLinkResult {
    let destination: DeepLinkDestination
    let message: String?
}

enum DeepLinkError: LocalizedError {
    case unsupportedAction(String)
    case unsupportedParameter(String)
    case invalidValue(name: String, value: String)

    var errorDescription: String? {
        switch self {
        case .unsupportedAction(let action):
            return "Неизвестная команда deep link: \(action)"
        case .unsupportedParameter(let parameter):
            return "Неизвестный параметр конфигурации: \(parameter)"
        case .invalidValue(let name, let value):
            return "Некорректное значение \(name): \(value)"
        }
    }
}

@MainActor
enum DeepLinkRouter {
    static func handle(
        _ url: URL,
        proxy: ProxyViewModel,
        settings: AppSettings
    ) async throws -> DeepLinkResult {
        guard url.scheme?.lowercased() == "tgwsproxy" else {
            throw DeepLinkError.unsupportedAction(url.scheme ?? "")
        }

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let action = normalizedAction(url, items: items)

        switch action {
        case "", "home":
            return DeepLinkResult(destination: .home, message: nil)
        case "settings":
            return DeepLinkResult(destination: .settings, message: nil)
        case "logs":
            return DeepLinkResult(destination: .logs, message: nil)
        case "info":
            return DeepLinkResult(destination: .info, message: nil)
        case "start":
            if !proxy.isRunning {
                proxy.start()
            }
            return DeepLinkResult(destination: .home, message: "Прокси запускается")
        case "stop":
            if proxy.state != .stopped {
                await proxy.stopAndWait()
            }
            return DeepLinkResult(destination: .home, message: "Прокси остановлен")
        case "collect_logs":
            LogStore.shared.startCapturing()
            if try optionalBool("copy", in: items) == true {
                UIPasteboard.general.string = LogStore.shared.report(
                    context: proxy.diagnosticsContext
                )
                return DeepLinkResult(
                    destination: .logs,
                    message: "Отчёт и логи скопированы"
                )
            }
            return DeepLinkResult(destination: .logs, message: "Сбор логов включён")
        case "update_cf_link", "update_cf_domains", "refresh_cf":
            let refreshed = await proxy.refreshCloudflareDomains()
            return DeepLinkResult(
                destination: .settings,
                message: refreshed ? "Список CF Worker обновлён" : "Не удалось обновить список CF Worker"
            )
        case "add_cf_domain":
            guard let raw = value("domain", in: items) ?? value("cf_domain", in: items) else {
                throw DeepLinkError.invalidValue(name: "domain", value: "")
            }
            let domain = try validatedDomain(raw)
            var configuration = proxy.configuration
            configuration.cloudflareEnabled = true
            configuration.cloudflareDomain = domain
            await proxy.applyConfiguration(configuration, start: nil)
            proxy.reloadCloudflareDomains()
            return DeepLinkResult(destination: .settings, message: "CF Worker добавлен: \(domain)")
        case "clear_cf_domain", "remove_cf_domain":
            var configuration = proxy.configuration
            configuration.cloudflareDomain = ""
            await proxy.applyConfiguration(configuration, start: nil)
            proxy.reloadCloudflareDomains()
            return DeepLinkResult(destination: .settings, message: "Пользовательский CF Worker удалён")
        case "show_cf_domains":
            proxy.reloadCloudflareDomains()
            return DeepLinkResult(destination: .settings, message: "CF Worker: \(proxy.cloudflareDomains.count)")
        case "config":
            return try await applyConfiguration(items, proxy: proxy, settings: settings)
        default:
            throw DeepLinkError.unsupportedAction(action)
        }
    }

    private static func applyConfiguration(
        _ items: [URLQueryItem],
        proxy: ProxyViewModel,
        settings: AppSettings
    ) async throws -> DeepLinkResult {
        var configuration = proxy.configuration
        var shouldStart: Bool?
        var destination: DeepLinkDestination = .settings
        var changed: [String] = []
        var autoStart = settings.autoStart
        var reconnect = settings.reconnect
        var liquidGlass = settings.liquidGlass
        var liveActivities = settings.liveActivities
        var notifications = settings.notifications
        var haptics = settings.haptics
        var language = settings.language
        var theme = settings.theme
        var accent = settings.accent

        for item in items {
            let name = item.name.lowercased()
            if name == "action" {
                continue
            }
            guard let value = item.value, !value.isEmpty else {
                throw DeepLinkError.invalidValue(name: name, value: item.value ?? "")
            }

            switch name {
            case "addr", "address", "server", "host":
                guard value.count <= 255, !value.contains(where: \.isWhitespace) else {
                    throw DeepLinkError.invalidValue(name: name, value: value)
                }
                configuration.bindAddress = value
                changed.append("адрес")

            case "port":
                guard let port = Int(value), (1...65535).contains(port) else {
                    throw DeepLinkError.invalidValue(name: name, value: value)
                }
                configuration.port = port
                changed.append("порт")

            case "pool", "pool_size", "poolsize":
                guard let pool = Int(value), ProxyConfiguration.allowedPoolSizes.contains(pool) else {
                    throw DeepLinkError.invalidValue(name: name, value: value)
                }
                configuration.poolSize = pool
                changed.append("пул")

            case "cf_proxy", "cloudflare", "cf":
                configuration.cloudflareEnabled = try bool(value, name: name)
                changed.append("Cloudflare")

            case "cf_domain", "domain":
                configuration.cloudflareDomain = try validatedDomain(value)
                changed.append("CF-домен")

            case "secret":
                let secret = value.lowercased().hasPrefix("dd")
                    ? String(value.dropFirst(2))
                    : value
                guard secret.count == 32, secret.allSatisfy(\.isHexDigit) else {
                    throw DeepLinkError.invalidValue(name: name, value: "скрыто")
                }
                configuration.secret = secret.lowercased()
                changed.append("секрет")

            case "dc", "dc_addresses", "dcaddresses":
                guard value.count <= 4096 else {
                    throw DeepLinkError.invalidValue(name: name, value: "слишком длинное")
                }
                configuration.dcAddresses = value
                changed.append("Telegram DC")

            case "verbose":
                configuration.verboseLogging = try bool(value, name: name)
                changed.append("verbose")

            case "autostart", "auto_start":
                autoStart = try bool(value, name: name)
                changed.append("авто-старт")

            case "reconnect", "auto_reconnect":
                reconnect = try bool(value, name: name)
                changed.append("переподключение")

            case "glass", "liquid_glass":
                liquidGlass = try bool(value, name: name)
                changed.append("Liquid Glass")

            case "live_activity", "dynamic_island":
                liveActivities = try bool(value, name: name)
                changed.append("Live Activity")

            case "notifications":
                notifications = try bool(value, name: name)
                changed.append("уведомления")

            case "haptics":
                haptics = try bool(value, name: name)
                changed.append("хаптика")

            case "language", "lang":
                language = try parseLanguage(value)
                changed.append("язык")

            case "theme":
                guard let parsedTheme = AppTheme(rawValue: value.lowercased()) else {
                    throw DeepLinkError.invalidValue(name: name, value: value)
                }
                theme = parsedTheme
                changed.append("тема")

            case "accent":
                guard let parsedAccent = AccentChoice(rawValue: value.lowercased()) else {
                    throw DeepLinkError.invalidValue(name: name, value: value)
                }
                accent = parsedAccent
                changed.append("акцент")

            case "start":
                shouldStart = try bool(value, name: name)

            case "open":
                destination = try parseDestination(value)

            default:
                throw DeepLinkError.unsupportedParameter(item.name)
            }
        }

        settings.autoStart = autoStart
        settings.reconnect = reconnect
        settings.liquidGlass = liquidGlass
        settings.liveActivities = liveActivities
        settings.notifications = notifications
        settings.haptics = haptics
        settings.language = language
        settings.theme = theme
        settings.accent = accent
        if notifications {
            NotificationManager.requestAuthorization()
        }
        ActivityManager.setEnabled(
            liveActivities,
            mode: proxy.modeTitle,
            running: proxy.isRunning
        )

        await proxy.applyConfiguration(configuration, start: shouldStart)

        let unique = Array(NSOrderedSet(array: changed)) as? [String] ?? changed
        let summary = unique.isEmpty
            ? "Конфигурация не изменена"
            : "Применено: " + unique.joined(separator: ", ")
        return DeepLinkResult(destination: destination, message: summary)
    }

    private static func normalizedAction(_ url: URL, items: [URLQueryItem]) -> String {
        if let queryAction = value("action", in: items), !queryAction.isEmpty {
            return queryAction.lowercased()
        }
        if let host = url.host, !host.isEmpty {
            return host.lowercased()
        }
        return url.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
    }

    private static func value(_ name: String, in items: [URLQueryItem]) -> String? {
        items.first(where: { $0.name.lowercased() == name })?.value
    }

    private static func validatedDomain(_ value: String) throws -> String {
        let domain = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard domain.count <= 253,
              domain.contains("."),
              !domain.contains(where: \.isWhitespace),
              domain.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "." || $0 == "-" })
        else {
            throw DeepLinkError.invalidValue(name: "domain", value: value)
        }
        return domain
    }

    private static func bool(_ value: String, name: String) throws -> Bool {
        switch value.lowercased() {
        case "1", "true", "yes", "on":
            return true
        case "0", "false", "no", "off":
            return false
        default:
            throw DeepLinkError.invalidValue(name: name, value: value)
        }
    }

    private static func optionalBool(
        _ name: String,
        in items: [URLQueryItem]
    ) throws -> Bool? {
        guard let item = items.first(where: { $0.name.lowercased() == name }) else {
            return nil
        }
        return try bool(item.value ?? "", name: name)
    }

    private static func parseLanguage(_ value: String) throws -> AppLanguage {
        switch value.lowercased() {
        case "system", "auto":
            return .system
        case "ru", "rus", "russian":
            return .russian
        case "en", "eng", "english":
            return .english
        default:
            throw DeepLinkError.invalidValue(name: "language", value: value)
        }
    }

    private static func parseDestination(_ value: String) throws -> DeepLinkDestination {
        switch value.lowercased() {
        case "home":
            return .home
        case "settings", "config":
            return .settings
        case "logs":
            return .logs
        case "info", "about":
            return .info
        default:
            throw DeepLinkError.invalidValue(name: "open", value: value)
        }
    }
}
