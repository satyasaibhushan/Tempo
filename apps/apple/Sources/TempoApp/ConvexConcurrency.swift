@preconcurrency import ConvexMobile

// Convex documents its client as safe to call from the main actor, but the
// 0.8.x Swift interface does not yet declare Sendable for Swift 6 consumers.
extension ConvexClient: @retroactive @unchecked Sendable {}
