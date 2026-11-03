import Foundation

final class KeyboardModel: ObservableObject {
    enum Category: String, CaseIterable, Identifiable {
        case recent, faces, hearts, gestures
        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .recent: "clock"
            case .faces: "face.smiling"
            case .hearts: "heart"
            case .gestures: "hand.thumbsup"
            }
        }
    }

    @Published var faceMatches: [String] = []
    @Published var recents: [String] = []
    @Published var category: Category = .faces
    @Published var showsGlobe = true
    @Published var hasFullAccess = false

    var insert: (String) -> Void = { _ in }
    var deleteBackward: () -> Void = {}
    var nextKeyboard: () -> Void = {}
    var openScanner: () -> Void = {}

    var emojisForCategory: [String] {
        switch category {
        case .recent: recents
        case .faces: EmojiCatalog.faces.map(\.emoji)
        case .hearts: EmojiCatalog.hearts
        case .gestures: EmojiCatalog.gestures
        }
    }

    func reload() {
        let matches = SharedStore.freshSnapshot()?.emojis ?? []
        if matches != faceMatches { faceMatches = matches }
        let latestRecents = SharedStore.recents()
        if latestRecents != recents { recents = latestRecents }
    }

    func tap(_ emoji: String) {
        insert(emoji)
        SharedStore.addRecent(emoji)
        recents = SharedStore.recents()
    }
}
