import Foundation

/// The facial signals emojis are matched on. Every value is normalised to 0...1.
enum Feature: String, CaseIterable, Codable, CodingKeyRepresentable {
    case smile, frown, jawOpen, eyesClosed, wink, eyesWide, squint
    case browUp, browDown, browRaise // browRaise = one eyebrow up
    case pucker, cheekPuff, tongueOut, sneer, smirk, grimace

    var label: String {
        switch self {
        case .smile: "Smile"
        case .frown: "Frown"
        case .jawOpen: "Mouth open"
        case .eyesClosed: "Eyes closed"
        case .wink: "Wink"
        case .eyesWide: "Wide eyes"
        case .squint: "Squint"
        case .browUp: "Brows up"
        case .browDown: "Brows down"
        case .browRaise: "One brow up"
        case .pucker: "Pucker"
        case .cheekPuff: "Puffed cheeks"
        case .tongueOut: "Tongue out"
        case .sneer: "Sneer"
        case .smirk: "Smirk"
        case .grimace: "Grimace"
        }
    }
}

struct FeatureReading: Identifiable, Equatable {
    let feature: Feature
    let value: Double
    var id: Feature { feature }
}

/// A snapshot of someone's expression as a set of 0...1 feature intensities.
struct FaceFeatures: Codable, Equatable {
    private(set) var values: [Feature: Double] = [:]

    init(_ values: [Feature: Double] = [:]) {
        for (feature, value) in values { self[feature] = value }
    }

    subscript(_ feature: Feature) -> Double {
        get { values[feature] ?? 0 }
        set { values[feature] = min(max(newValue, 0), 1) }
    }

    static let neutral = FaceFeatures()

    /// Linear blend toward `other` — used as an exponential moving average to smooth tracking jitter.
    func blended(toward other: FaceFeatures, amount: Double) -> FaceFeatures {
        var out = FaceFeatures()
        for f in Feature.allCases {
            out[f] = self[f] + (other[f] - self[f]) * amount
        }
        return out
    }

    /// The strongest signals, strongest first.
    func dominant(limit: Int = 3, threshold: Double = 0.25) -> [FeatureReading] {
        Feature.allCases
            .map { FeatureReading(feature: $0, value: self[$0]) }
            .filter { $0.value >= threshold }
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0 }
    }
}
