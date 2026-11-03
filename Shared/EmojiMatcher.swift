import Foundation

struct EmojiMatch: Identifiable, Hashable {
    let entry: EmojiEntry
    /// 0...1, higher is a closer match.
    let score: Double
    var id: String { entry.emoji }
}

/// Ranks emojis by how closely their expression target matches a face.
///
/// Uses a weighted RMS distance over every feature: features an emoji explicitly
/// describes count fully, features it leaves out are expected to be ~0 but count less,
/// so a strong unrelated signal (e.g. tongue out) still pushes non-matching emojis down.
enum EmojiMatcher {
    static let specifiedWeight = 1.0
    static let unspecifiedWeight = 0.4

    static func rank(
        _ face: FaceFeatures,
        in catalog: [EmojiEntry] = EmojiCatalog.faces,
        limit: Int = 8
    ) -> [EmojiMatch] {
        catalog
            .map { EmojiMatch(entry: $0, score: score(face, against: $0)) }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    static func score(_ face: FaceFeatures, against entry: EmojiEntry) -> Double {
        var distance = 0.0
        var totalWeight = 0.0
        for feature in Feature.allCases {
            let target = entry.target[feature]
            let weight = target == nil ? unspecifiedWeight : specifiedWeight
            let diff = face[feature] - (target ?? 0)
            distance += weight * diff * diff
            totalWeight += weight
        }
        let rms = (distance / totalWeight).squareRoot()
        return max(0, 1 - rms * 2.5)
    }
}
