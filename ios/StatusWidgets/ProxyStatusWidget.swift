import SwiftUI
import WidgetKit

struct ProxyStatusEntry: TimelineEntry {
    let date: Date
    let connected: Bool
    let upload: String
    let download: String
    let active: String
}

struct ProxyStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProxyStatusEntry {
        ProxyStatusEntry(date: .now, connected: true, upload: "1.2 MB", download: "8.4 MB", active: "1")
    }

    func getSnapshot(in context: Context, completion: @escaping (ProxyStatusEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProxyStatusEntry>) -> Void) {
        completion(Timeline(entries: [entry()], policy: .after(.now.addingTimeInterval(60))))
    }

    private func entry() -> ProxyStatusEntry {
        ProxyStatusEntry(
            date: .now,
            connected: WidgetStatusStore.connected,
            upload: WidgetStatusStore.upload,
            download: WidgetStatusStore.download,
            active: WidgetStatusStore.active
        )
    }
}

struct ProxyStatusWidget: Widget {
    let kind = "TgWsProxy.Status"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProxyStatusProvider()) { entry in
            ProxyWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("TG WS Proxy")
        .description("Статус прокси и текущий трафик.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ProxyWidgetView: View {
    let entry: ProxyStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.blue)
                Text("TG WS Proxy")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(entry.connected ? .green : .secondary)
                    .frame(width: 8, height: 8)
            }
            Text(entry.connected ? "Прокси работает" : "Не подключено")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(entry.connected ? .green : .secondary)
            HStack {
                metric("↓", entry.download)
                metric("↑", entry.upload)
                metric("●", entry.active)
            }
            Button(intent: WidgetProxyCommandIntent()) {
                Label(
                    entry.connected ? "Остановить" : "Включить",
                    systemImage: entry.connected ? "stop.fill" : "play.fill"
                )
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(entry.connected ? .red : .blue)
        }
    }

    private func metric(_ icon: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(icon).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.monospacedDigit().weight(.medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
