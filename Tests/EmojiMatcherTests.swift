import XCTest
@testable import FaceKey

final class EmojiMatcherTests: XCTestCase {
    private func best(_ values: [Feature: Double]) -> String? {
        EmojiMatcher.rank(FaceFeatures(values), limit: 1).first?.entry.emoji
    }

    func testNeutralFaceMatchesNeutralEmoji() {
        XCTAssertEqual(best([:]), "😐")
    }

    func testExpressions() {
        XCTAssertEqual(best([.jawOpen: 0.95, .eyesWide: 0.9, .browUp: 0.85]), "😲")
        XCTAssertEqual(best([.wink: 1, .tongueOut: 0.8, .jawOpen: 0.4]), "😜")
        XCTAssertEqual(best([.pucker: 1]), "😗")
        XCTAssertEqual(best([.cheekPuff: 0.9]), "🐡")
        XCTAssertEqual(best([.browDown: 0.95, .frown: 0.4]), "😠")
        XCTAssertEqual(best([.eyesClosed: 1, .jawOpen: 0.25]), "😴")
    }

    func testEveryEmojiIsItsOwnBestMatch() {
        for entry in EmojiCatalog.faces {
            XCTAssertEqual(best(entry.target), entry.emoji, "\(entry.name) is shadowed by another entry")
        }
    }

    func testScoresAreSortedAndBounded() {
        let matches = EmojiMatcher.rank(FaceFeatures([.smile: 0.6]), limit: 20)
        XCTAssertEqual(matches.map(\.score), matches.map(\.score).sorted(by: >))
        XCTAssertTrue(matches.allSatisfy { (0...1).contains($0.score) })
    }

    func testCatalogHasNoDuplicates() {
        let emojis = EmojiCatalog.faces.map(\.emoji)
        XCTAssertEqual(emojis.count, Set(emojis).count)
    }

    func testFeaturesAreClamped() {
        var face = FaceFeatures()
        face[.smile] = 3
        face[.frown] = -1
        XCTAssertEqual(face[.smile], 1)
        XCTAssertEqual(face[.frown], 0)
    }
}
