import ActivityKit
import SwiftUI
import WidgetKit

struct ProxyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ProxyActivityAttributes.self) { context in
            Link(destination: URL(string: "tgwsproxy://home")!) {
                HStack(spacing: 12) {
                    statusDot(context.state.connected, size: 10)
                    Text("TG WS Proxy")
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Text("↓ \(context.state.download)   ↑ \(context.state.upload)")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .activityBackgroundTint(.black.opacity(0.82))
            .activitySystemActionForegroundColor(.white)
            .widgetURL(URL(string: "tgwsproxy://home"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.download, systemImage: "arrow.down")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.green)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label(context.state.upload, systemImage: "arrow.up")
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 6) {
                        statusDot(context.state.connected, size: 8)
                        Text("TG WS Proxy")
                            .font(.callout.weight(.semibold))
                    }
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    statusDot(context.state.connected, size: 7)
                    Text("TG WS Proxy")
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                }
            } compactTrailing: {
                EmptyView()
            } minimal: {
                statusDot(context.state.connected, size: 8)
            }
            .keylineTint(context.state.connected ? .green : .gray)
            .widgetURL(URL(string: "tgwsproxy://home"))
        }
    }

    private func statusDot(_ connected: Bool, size: CGFloat) -> some View {
        Circle()
            .fill(connected ? Color.green : Color.secondary)
            .frame(width: size, height: size)
    }
}
