import SwiftUI
import WidgetKit

@main
struct TempoWidgetsBundle: WidgetBundle {
    var body: some Widget {
        CurrentTimerWidget()
        SummaryWidget()
        LiveWeekWidget()
    }
}
