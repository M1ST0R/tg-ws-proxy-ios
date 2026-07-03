import SwiftUI
import WidgetKit

@main
struct StatusWidgetsBundle: WidgetBundle {
    var body: some Widget {
#if TGWS_HOME_WIDGET_COMPONENT
        ProxyStatusWidget()
#endif
#if TGWS_LIVE_ACTIVITY_COMPONENT
        ProxyLiveActivity()
#endif
#if TGWS_CONTROL_WIDGET_COMPONENT
        if #available(iOSApplicationExtension 18.0, *) {
            ProxyControlWidget()
        }
#endif
    }
}
