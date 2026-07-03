import SwiftUI
import Network

@MainActor
final class Pinger: ObservableObject {
    struct Result: Identifiable {
        let id = UUID()
        let name: String
        let host: String
        var ms: Int?
        var ok: Bool?
    }

    @Published var results: [Result] = []
    @Published var running = false

    private var targets: [(String, String)] {
        let cfDomain = NativeProxy.cloudflareDomains().first ?? "cloudflare-dns.com"
        return [
            ("DC1", "149.154.175.50"),
            ("DC2", "149.154.167.51"),
            ("DC3", "149.154.175.100"),
            ("DC4", "149.154.167.91"),
            ("DC5", "149.154.171.5"),
            ("Telegram WSS", "kws1.web.telegram.org"),
            ("Cloudflare", cfDomain),
        ]
    }

    func run() {
        guard !running else { return }
        running = true
        results = targets.map { Result(name: $0.0, host: $0.1, ms: nil, ok: nil) }

        Task {
            await withTaskGroup(of: (Int, Int?).self) { group in
                for (index, target) in targets.enumerated() {
                    group.addTask { (index, await Self.ping(host: target.1, port: 443)) }
                }
                for await (index, ms) in group {
                    if let ms {
                        results[index].ms = ms
                        results[index].ok = true
                    } else {
                        results[index].ok = false
                    }
                }
            }
            running = false
        }
    }

    private static func ping(host: String, port: UInt16) async -> Int? {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(rawValue: port)!,
                using: .tcp
            )
            let start = DispatchTime.now()
            let lock = DispatchQueue(label: "ping.\(host)")
            var finished = false

            let finish: (Int?) -> Void = { value in
                lock.async {
                    guard !finished else { return }
                    finished = true
                    connection.cancel()
                    continuation.resume(returning: value)
                }
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let ns = DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds
                    finish(Int(Double(ns) / 1_000_000))
                case .failed, .cancelled:
                    finish(nil)
                default:
                    break
                }
            }
            connection.start(queue: .global())
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) { finish(nil) }
        }
    }
}

struct PingView: View {
    @StateObject private var pinger = Pinger()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(pinger.results) { result in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.name).font(.callout.weight(.medium))
                                Text(result.host).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            status(result)
                        }
                    }
                } header: {
                    Text("Telegram DC / WSS / Cloudflare · TCP 443".tgLoc)
                } footer: {
                    Text("Задержка TCP-подключения напрямую (без прокси).".tgLoc)
                }
            }
            .navigationTitle("Задержка до DC".tgLoc)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть".tgLoc) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { pinger.run() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(pinger.running)
                }
            }
            .onAppear { if pinger.results.isEmpty { pinger.run() } }
        }
    }

    @ViewBuilder
    private func status(_ r: Pinger.Result) -> some View {
        switch r.ok {
        case nil:
            ProgressView()
        case .some(true):
            Text("\(r.ms ?? 0) мс")
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(color(for: r.ms ?? 9999))
        case .some(false):
            Text("недоступен".tgLoc)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func color(for ms: Int) -> Color {
        switch ms {
        case ..<100: .tgConnected
        case ..<250: .orange
        default: .red
        }
    }
}
