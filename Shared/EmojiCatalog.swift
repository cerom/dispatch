import Foundation

/// An emoji plus the expression it represents. Features left out of `target`
/// are expected to be ~0 (but are weighted less when matching).
struct EmojiEntry: Identifiable, Hashable {
    let emoji: String
    let name: String
    let target: [Feature: Double]
    var id: String { emoji }

    init(_ emoji: String, _ name: String, _ target: [Feature: Double]) {
        self.emoji = emoji
        self.name = name
        self.target = target
    }
}

enum EmojiCatalog {
    /// Face emojis with hand-tuned expression targets. Order doubles as the keyboard's display order.
    static let faces: [EmojiEntry] = [
        // Neutral & happy
        .init("😐", "neutral", [:]),
        .init("🙂", "slightly smiling", [.smile: 0.4]),
        .init("😊", "smiling eyes", [.smile: 0.7, .squint: 0.5]),
        .init("😀", "grinning", [.smile: 0.8, .jawOpen: 0.4]),
        .init("😃", "grinning, big eyes", [.smile: 0.8, .jawOpen: 0.5, .eyesWide: 0.4]),
        .init("😄", "grinning, smiling eyes", [.smile: 0.9, .jawOpen: 0.5, .squint: 0.6]),
        .init("😁", "beaming", [.smile: 1.0, .squint: 0.7, .grimace: 0.3]),
        .init("😆", "squinting laugh", [.smile: 0.9, .jawOpen: 0.6, .eyesClosed: 0.9]),
        .init("😂", "tears of joy", [.smile: 0.8, .jawOpen: 0.7, .eyesClosed: 0.8, .browUp: 0.5]),
        .init("🤣", "rolling laughing", [.smile: 1.0, .jawOpen: 0.9, .eyesClosed: 0.9, .smirk: 0.4]),
        .init("🥰", "smiling with hearts", [.smile: 0.7, .squint: 0.6, .browUp: 0.4]),
        .init("😍", "heart eyes", [.smile: 0.8, .jawOpen: 0.3, .eyesWide: 0.5, .browUp: 0.3]),
        .init("🤩", "star-struck", [.smile: 0.9, .jawOpen: 0.5, .eyesWide: 0.8, .browUp: 0.6]),

        // Playful
        .init("😉", "wink", [.wink: 0.9, .smile: 0.5]),
        .init("😜", "winking tongue", [.wink: 0.9, .tongueOut: 0.8, .jawOpen: 0.4]),
        .init("🤪", "zany", [.wink: 0.7, .tongueOut: 0.7, .jawOpen: 0.5, .eyesWide: 0.6, .browRaise: 0.5]),
        .init("😛", "tongue out", [.tongueOut: 0.9, .jawOpen: 0.3]),
        .init("😝", "squinting tongue", [.tongueOut: 0.9, .jawOpen: 0.4, .eyesClosed: 0.8]),
        .init("😋", "yum", [.tongueOut: 0.5, .smile: 0.6]),
        .init("😏", "smirk", [.smirk: 0.7, .smile: 0.3, .browRaise: 0.3]),

        // Skeptical & unimpressed
        .init("🤨", "raised eyebrow", [.browRaise: 0.9, .browDown: 0.3]),
        .init("🧐", "monocle", [.browRaise: 0.7, .wink: 0.5]),
        .init("🤔", "thinking", [.smirk: 0.4, .browDown: 0.4, .squint: 0.3]),
        .init("😒", "unamused", [.frown: 0.4, .smirk: 0.3, .squint: 0.4, .browDown: 0.2]),
        .init("🙄", "eye roll", [.browUp: 0.6, .smirk: 0.3, .frown: 0.2]),
        .init("😑", "expressionless", [.eyesClosed: 0.9]),
        .init("😬", "grimacing", [.grimace: 0.9, .smile: 0.3, .eyesWide: 0.3]),

        // Surprise & fear
        .init("😮", "open mouth", [.jawOpen: 0.7, .browUp: 0.3]),
        .init("😯", "hushed", [.jawOpen: 0.4, .pucker: 0.4, .browUp: 0.5]),
        .init("😲", "astonished", [.jawOpen: 0.9, .eyesWide: 0.9, .browUp: 0.9]),
        .init("😳", "flushed", [.eyesWide: 0.9, .browUp: 0.6]),
        .init("😱", "screaming", [.jawOpen: 1.0, .eyesWide: 0.8, .browUp: 0.9, .grimace: 0.5]),
        .init("😨", "fearful", [.browUp: 0.8, .jawOpen: 0.4, .grimace: 0.5, .eyesWide: 0.4]),

        // Sad
        .init("🥺", "pleading", [.browUp: 0.9, .eyesWide: 0.5, .frown: 0.3]),
        .init("😟", "worried", [.frown: 0.5, .browUp: 0.7]),
        .init("🙁", "slightly frowning", [.frown: 0.4]),
        .init("☹️", "frowning", [.frown: 0.8]),
        .init("😢", "crying", [.frown: 0.6, .browUp: 0.6, .squint: 0.3]),
        .init("😭", "sobbing", [.frown: 0.5, .jawOpen: 0.7, .eyesClosed: 0.9, .browUp: 0.5]),
        .init("😞", "disappointed", [.frown: 0.6, .eyesClosed: 0.4]),
        .init("😔", "pensive", [.frown: 0.3, .eyesClosed: 0.6, .browUp: 0.2]),
        .init("😩", "weary", [.frown: 0.6, .jawOpen: 0.5, .browUp: 0.6, .eyesClosed: 0.5]),
        .init("😫", "tired", [.frown: 0.5, .jawOpen: 0.6, .eyesClosed: 0.8, .browDown: 0.4]),
        .init("😖", "confounded", [.frown: 0.5, .eyesClosed: 0.8, .browDown: 0.5, .sneer: 0.4]),
        .init("😣", "persevering", [.eyesClosed: 0.8, .browDown: 0.5, .grimace: 0.5]),

        // Angry & disgusted
        .init("😠", "angry", [.browDown: 0.9, .frown: 0.4]),
        .init("😡", "pouting", [.browDown: 1.0, .frown: 0.6, .sneer: 0.5]),
        .init("🤬", "cursing", [.browDown: 1.0, .jawOpen: 0.6, .grimace: 0.6, .sneer: 0.5]),
        .init("😤", "huffing", [.browDown: 0.6, .sneer: 0.7, .cheekPuff: 0.3]),
        .init("🤢", "nauseated", [.sneer: 0.9, .frown: 0.5, .squint: 0.5]),
        .init("🤮", "vomiting", [.sneer: 0.7, .jawOpen: 0.9, .eyesClosed: 0.5, .tongueOut: 0.4]),
        .init("🥵", "hot", [.tongueOut: 0.6, .jawOpen: 0.6, .frown: 0.3, .browUp: 0.3]),

        // Kisses
        .init("😗", "kissing", [.pucker: 0.9]),
        .init("😙", "kissing, smiling eyes", [.pucker: 0.9, .smile: 0.3, .squint: 0.5]),
        .init("😚", "kissing, closed eyes", [.pucker: 0.9, .eyesClosed: 0.8]),
        .init("😘", "blowing a kiss", [.pucker: 0.9, .wink: 0.8]),

        // Sleepy & puffy
        .init("😴", "sleeping", [.eyesClosed: 1.0, .jawOpen: 0.3]),
        .init("🥱", "yawning", [.jawOpen: 1.0, .eyesClosed: 0.7]),
        .init("😪", "sleepy", [.eyesClosed: 0.7, .frown: 0.2, .pucker: 0.2]),
        .init("😮‍💨", "exhaling", [.cheekPuff: 0.6, .pucker: 0.6, .eyesClosed: 0.4]),
        .init("🐡", "puffed cheeks", [.cheekPuff: 1.0]),
    ]

    static let hearts: [String] = "❤️🧡💛💚💙💜🖤🤍🤎💔❣️💕💞💓💗💖💘💝💟".map(String.init)
    static let gestures: [String] = "👍👎👌✌️🤞🤟🤘🤙👋👏🙌🙏💪🫶👀🔥✨🎉💯✅".map(String.init)
}
