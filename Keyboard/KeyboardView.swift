import SwiftUI

struct KeyboardView: View {
    static let height: CGFloat = 300

    @ObservedObject var model: KeyboardModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 8)

    var body: some View {
        VStack(spacing: 0) {
            faceBar
                .frame(height: 60)
            Divider()
            grid
            Divider()
            bottomBar
                .frame(height: 44)
        }
        .frame(height: Self.height)
    }

    // MARK: - Face matches

    private var faceBar: some View {
        HStack(spacing: 8) {
            Button(action: model.openScanner) {
                Image(systemName: "faceid")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Scan my face")

            if !model.hasFullAccess {
                hint("Turn on Allow Full Access in Settings → FaceKey → Keyboards to see face matches.")
            } else if model.faceMatches.isEmpty {
                hint("Tap the face button and pull a face 😜")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(model.faceMatches, id: \.self) { emoji in
                            Button { model.tap(emoji) } label: {
                                Text(emoji)
                                    .font(.system(size: 36))
                                    .frame(width: 48, height: 48)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Emoji grid

    private var grid: some View {
        ScrollView {
            let emojis = model.emojisForCategory
            if emojis.isEmpty {
                Text("Emojis you use show up here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button { model.tap(emoji) } label: {
                            Text(emoji)
                                .font(.system(size: 30))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 4) {
            if model.showsGlobe {
                key(systemImage: "globe", label: "Next keyboard", action: model.nextKeyboard)
            }
            ForEach(KeyboardModel.Category.allCases) { category in
                key(systemImage: category.symbol, label: category.rawValue,
                    selected: model.category == category) {
                    model.category = category
                }
            }
            Button { model.insert(" ") } label: {
                Text("space")
                    .font(.callout)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            key(systemImage: "delete.left", label: "Delete", action: model.deleteBackward)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    private func key(systemImage: String, label: String, selected: Bool = false,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17))
                .frame(width: 38, height: 36)
                .background(selected ? Color(.systemBackground) : .clear,
                            in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
