import AppIntents
import TempoCore

enum SummaryRangeIntent: String, AppEnum {
    case day
    case week
    case month

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Range")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .day: "Day",
        .week: "Week",
        .month: "Month",
    ]

    var widgetRange: WidgetRange {
        WidgetRange(rawValue: rawValue) ?? .week
    }
}

struct FolderFilterEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Folder")
    static let defaultQuery = FolderFilterQuery()
    static let all = FolderFilterEntity(id: "all-folders", name: "All folders")

    let id: String
    let name: String

    var filterId: String? {
        id == Self.all.id ? nil : id
    }

    var selectedName: String? {
        id == Self.all.id ? nil : name
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct FolderFilterQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FolderFilterEntity] {
        folderEntities.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [FolderFilterEntity] {
        folderEntities
    }

    func defaultResult() async -> FolderFilterEntity? {
        .all
    }

    private var folderEntities: [FolderFilterEntity] {
        [FolderFilterEntity.all] + (WidgetSnapshotStore.load()?.folders ?? []).map {
            FolderFilterEntity(id: $0.id, name: $0.name)
        }
    }
}

struct LabelFilterEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Label")
    static let defaultQuery = LabelFilterQuery()
    static let all = LabelFilterEntity(id: "all-labels", name: "All labels")

    let id: String
    let name: String

    var filterId: String? {
        id == Self.all.id ? nil : id
    }

    var selectedName: String? {
        id == Self.all.id ? nil : name
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct LabelFilterQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [LabelFilterEntity] {
        labelEntities.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [LabelFilterEntity] {
        labelEntities
    }

    func defaultResult() async -> LabelFilterEntity? {
        .all
    }

    private var labelEntities: [LabelFilterEntity] {
        [LabelFilterEntity.all] + (WidgetSnapshotStore.load()?.labels ?? []).map {
            LabelFilterEntity(id: $0.id, name: $0.name)
        }
    }
}

struct SummaryWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Tracked time"
    static let description = IntentDescription(
        "Choose a time range and optionally narrow the widget to one folder or label."
    )

    @Parameter(title: "Range", default: .week)
    var range: SummaryRangeIntent

    @Parameter(title: "Folder")
    var folder: FolderFilterEntity?

    @Parameter(title: "Label")
    var label: LabelFilterEntity?

    init() {
        folder = .all
        label = .all
    }

    init(
        range: SummaryRangeIntent,
        folder: FolderFilterEntity? = .all,
        label: LabelFilterEntity? = .all
    ) {
        self.range = range
        self.folder = folder
        self.label = label
    }
}

struct LiveWeekWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Live week"
    static let description = IntentDescription(
        "Choose a folder and label for the live timer and weekly breakdown."
    )

    @Parameter(title: "Folder")
    var folder: FolderFilterEntity?

    @Parameter(title: "Label")
    var label: LabelFilterEntity?

    init() {
        folder = .all
        label = .all
    }

    init(
        folder: FolderFilterEntity? = .all,
        label: LabelFilterEntity? = .all
    ) {
        self.folder = folder
        self.label = label
    }
}
