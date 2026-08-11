public struct StartTimerRequest: Equatable, Sendable {
    public let title: String
    public let notes: String?
    public let folderId: DocumentID?
    public let manualLabelIds: [DocumentID]

    public init(
        title: String = "",
        notes: String? = nil,
        folderId: DocumentID? = nil,
        manualLabelIds: [DocumentID] = []
    ) {
        self.title = title
        self.notes = notes
        self.folderId = folderId
        self.manualLabelIds = manualLabelIds
    }
}

public protocol TimerRepository: Sendable {
    func activeTimers() -> AsyncThrowingStream<[TimeEntry], Error>
    func startTimer(_ request: StartTimerRequest) async throws -> DocumentID
    func pauseTimer(id: DocumentID) async throws
    func resumeTimer(id: DocumentID) async throws
    func stopTimer(id: DocumentID) async throws
    func discardTimer(id: DocumentID) async throws
}
