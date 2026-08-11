import Foundation

public typealias DocumentID = String

public enum TimerStatus: String, Codable, CaseIterable, Sendable {
    case running
    case paused
    case completed
}

public enum WeekStart: String, Codable, Equatable, Sendable {
    case monday
    case sunday
}

public enum TimeFormat: String, Codable, Equatable, Sendable {
    case twelveHour = "12h"
    case twentyFourHour = "24h"
}

public struct TimeSegment: Codable, Equatable, Sendable {
    public let startTime: Int64
    public let endTime: Int64?

    public init(startTime: Int64, endTime: Int64? = nil) {
        self.startTime = startTime
        self.endTime = endTime
    }
}

public struct TimeEntry: Codable, Identifiable, Equatable, Sendable {
    public let id: DocumentID
    public let creationTime: Double?
    public let userId: DocumentID
    public let folderId: DocumentID?
    public let title: String
    public let notes: String?
    public let manualLabelIds: [DocumentID]
    public let status: TimerStatus
    public let segments: [TimeSegment]
    public let startedAt: Int64
    public let endedAt: Int64?
    public let durationSeconds: Int?
    public let createdAt: Int64
    public let updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case creationTime = "_creationTime"
        case userId, folderId, title, notes, manualLabelIds, status, segments
        case startedAt, endedAt, durationSeconds, createdAt, updatedAt
    }

    public init(
        id: DocumentID,
        creationTime: Double? = nil,
        userId: DocumentID,
        folderId: DocumentID? = nil,
        title: String,
        notes: String? = nil,
        manualLabelIds: [DocumentID] = [],
        status: TimerStatus,
        segments: [TimeSegment],
        startedAt: Int64,
        endedAt: Int64? = nil,
        durationSeconds: Int? = nil,
        createdAt: Int64,
        updatedAt: Int64
    ) {
        self.id = id
        self.creationTime = creationTime
        self.userId = userId
        self.folderId = folderId
        self.title = title
        self.notes = notes
        self.manualLabelIds = manualLabelIds
        self.status = status
        self.segments = segments
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Folder: Codable, Identifiable, Equatable, Sendable {
    public let id: DocumentID
    public let creationTime: Double?
    public let userId: DocumentID
    public let name: String
    public let color: String?
    public let parentFolderId: DocumentID?
    public let defaultLabelIds: [DocumentID]
    public let archived: Bool
    public let sortOrder: Double
    public let createdAt: Int64
    public let updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case creationTime = "_creationTime"
        case userId, name, color, parentFolderId, defaultLabelIds
        case archived, sortOrder, createdAt, updatedAt
    }
}

public struct Label: Codable, Identifiable, Equatable, Sendable {
    public let id: DocumentID
    public let creationTime: Double?
    public let userId: DocumentID
    public let name: String
    public let color: String
    public let createdAt: Int64
    public let updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case creationTime = "_creationTime"
        case userId, name, color, createdAt, updatedAt
    }
}

public struct UserProfile: Codable, Identifiable, Equatable, Sendable {
    public let id: DocumentID
    public let creationTime: Double?
    public let authProvider: String
    public let authSubject: String
    public let email: String?
    public let name: String?
    public let avatarUrl: String?
    public let timezone: String
    public let weekStart: WeekStart
    public let timeFormat: TimeFormat
    public let createdAt: Int64
    public let updatedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case creationTime = "_creationTime"
        case authProvider, authSubject, email, name, avatarUrl, timezone
        case weekStart, timeFormat, createdAt, updatedAt
    }
}
