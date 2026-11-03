import Foundation

/// What the app last saw, handed to the keyboard through the App Group.
struct FaceSnapshot: Codable, Equatable {
    var emojis: [String]
    var date: Date
}

/// App Group storage shared by the app and the keyboard extension.
/// The keyboard can only read this when the user grants it "Allow Full Access".
enum SharedStore {
    static let appGroupID: String =
        Bundle.main.object(forInfoDictionaryKey: "FaceKeyAppGroup") as? String ?? "group.com.example.facekey"

    /// Snapshots older than this are considered stale and hidden in the keyboard.
    static let snapshotLifetime: TimeInterval = 10 * 60

    private static let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
    private static let snapshotKey = "faceSnapshot"
    private static let recentsKey = "recentEmojis"

    static func saveSnapshot(_ snapshot: FaceSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func loadSnapshot() -> FaceSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(FaceSnapshot.self, from: data)
    }

    /// The latest snapshot, or nil if there is none or it is stale.
    static func freshSnapshot(now: Date = Date()) -> FaceSnapshot? {
        guard let snapshot = loadSnapshot(),
              now.timeIntervalSince(snapshot.date) < snapshotLifetime else { return nil }
        return snapshot
    }

    static func recents() -> [String] {
        defaults.stringArray(forKey: recentsKey) ?? []
    }

    static func addRecent(_ emoji: String, limit: Int = 32) {
        var list = recents().filter { $0 != emoji }
        list.insert(emoji, at: 0)
        defaults.set(Array(list.prefix(limit)), forKey: recentsKey)
    }
}
