import SwiftUI

struct ContentView: View {
    @StateObject private var tracker = FaceTracker()
    @Environment(\.scenePhase) private var scenePhase
    @State private var toast: String?
    @State private var showingSetup = false
    @State private var openedFromKeyboard = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if openedFromKeyboard { returnBanner }
                    camera
                    matchGrid
                    signals
                }
                .padding()
            }
            .navigationTitle("FaceKey")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSetup = true } label: {
                        Image(systemName: "keyboard")
                    }
                    .accessibilityLabel("Keyboard setup")
                }
            }
            .sheet(isPresented: $showingSetup) { KeyboardSetupView() }
            .overlay(alignment: .bottom) { toastView }
        }
        .task { tracker.start() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: tracker.start()
            case .background: tracker.pause()
            default: break
            }
        }
        .onOpenURL { _ in
            // Launched from the keyboard's scan button (facekey://scan).
            openedFromKeyboard = true
            tracker.isFrozen = false
        }
    }

    // MARK: - Sections

    private var returnBanner: some View {
        Label {
            Text("Make a face, then tap **◀︎** in the top-left corner to go back. Your matches will be waiting in the keyboard.")
                .font(.subheadline)
        } icon: {
            Image(systemName: "arrow.uturn.backward.circle.fill")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
    }

    private var camera: some View {
        ZStack {
            if FaceTracker.isSupported {
                FaceCameraView(session: tracker.session)
                if !tracker.isFaceVisible {
                    Text("Look at the camera")
                        .font(.headline)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            } else {
                ContentUnavailableView(
                    "Face tracking unavailable",
                    systemImage: "faceid",
                    description: Text("FaceKey needs an iPhone with a TrueDepth (Face ID) camera.")
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(alignment: .bottomLeading) {
            if let best = tracker.matches.first {
                Text(best.entry.emoji)
                    .font(.system(size: 72))
                    .padding(12)
                    .shadow(radius: 6)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.15), value: best.id)
            }
        }
        .overlay(alignment: .topTrailing) {
            if FaceTracker.isSupported {
                Button {
                    tracker.isFrozen.toggle()
                } label: {
                    Label(tracker.isFrozen ? "Resume" : "Freeze",
                          systemImage: tracker.isFrozen ? "play.fill" : "pause.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(12)
            }
        }
        .overlay(alignment: .bottom) {
            if let error = tracker.errorMessage {
                Text(error).font(.caption).padding(8)
                    .background(.red.opacity(0.85), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.bottom, 12)
            }
        }
    }

    private var matchGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Matches — tap to copy")
                .font(.headline)
            if tracker.matches.isEmpty {
                Text("Pull a face to see matching emojis.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(tracker.matches) { match in
                        Button { copy(match.entry.emoji) } label: {
                            VStack(spacing: 2) {
                                Text(match.entry.emoji).font(.system(size: 40))
                                Text("\(Int(match.score * 100))%")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 72)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(match.entry.name), \(Int(match.score * 100)) percent match")
                    }
                }
            }
        }
    }

    private var signals: some View {
        let readings = tracker.features.dominant(limit: 4)
        return VStack(alignment: .leading, spacing: 8) {
            Text("What I'm seeing").font(.headline)
            if readings.isEmpty {
                Text("Neutral face").foregroundStyle(.secondary)
            } else {
                ForEach(readings) { reading in
                    HStack {
                        Text(reading.feature.label).frame(width: 120, alignment: .leading)
                        ProgressView(value: reading.value)
                    }
                    .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Text(toast)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Actions

    private func copy(_ emoji: String) {
        UIPasteboard.general.string = emoji
        SharedStore.addRecent(emoji)
        withAnimation { toast = "Copied \(emoji)" }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { if toast == "Copied \(emoji)" { toast = nil } }
        }
    }
}

struct KeyboardSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Turn on the keyboard") {
                    Label("Open **Settings → FaceKey → Keyboards**", systemImage: "1.circle")
                    Label("Enable **FaceKey**", systemImage: "2.circle")
                    Label("Enable **Allow Full Access** so the keyboard can read your face matches", systemImage: "3.circle")
                }
                Section {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Section("Using it") {
                    Text("In any app, hold 🌐 and pick FaceKey. Tap the face button to jump here, pull a face, then tap ◀︎ in the top-left corner to go back — the closest emojis appear at the top of the keyboard.")
                }
                Section("Privacy") {
                    Text("Face tracking runs entirely on-device. FaceKey never records, stores or uploads camera images; only the matched emojis are shared with the keyboard. Full Access is used solely to read those matches.")
                }
            }
            .navigationTitle("Keyboard setup")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
