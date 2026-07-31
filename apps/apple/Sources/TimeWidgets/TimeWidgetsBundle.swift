import SwiftUI
import WidgetKit

@main
struct TimeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CurrentTimerWidget()
        SummaryWidget()
        LiveWeekWidget()
    }
}
