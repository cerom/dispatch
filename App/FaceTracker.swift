import ARKit
import SwiftUI

/// Runs ARKit face tracking and publishes smoothed features plus ranked emoji matches.
@MainActor
final class FaceTracker: NSObject, ObservableObject {
    @Published private(set) var features = FaceFeatures.neutral
    @Published private(set) var matches: [EmojiMatch] = []
    @Published private(set) var isFaceVisible = false
    @Published private(set) var errorMessage: String?
    @Published var isFrozen = false

    /// Face tracking needs a TrueDepth camera (iPhone X and later, minus SE models).
    static var isSupported: Bool { ARFaceTrackingConfiguration.isSupported }

    let session = ARSession()

    private var isRunning = false
    private var smoothed = FaceFeatures.neutral
    private var lastPublish = Date.distantPast
    private var lastShare = Date.distantPast

    private let smoothing = 0.35
    private let publishInterval: TimeInterval = 1.0 / 15
    private let shareInterval: TimeInterval = 0.5

    override init() {
        super.init()
        session.delegate = self // delegate callbacks arrive on the main queue
    }

    func start() {
        guard Self.isSupported, !isRunning else { return }
        let config = ARFaceTrackingConfiguration()
        config.maximumNumberOfTrackedFaces = 1
        config.isLightEstimationEnabled = false
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
        isRunning = true
        errorMessage = nil
    }

    func pause() {
        guard isRunning else { return }
        session.pause()
        isRunning = false
    }

    private func ingest(_ raw: FaceFeatures, tracked: Bool) {
        if isFaceVisible != tracked { isFaceVisible = tracked }
        guard tracked, !isFrozen else { return }

        smoothed = smoothed.blended(toward: raw, amount: smoothing)

        let now = Date()
        guard now.timeIntervalSince(lastPublish) >= publishInterval else { return }
        lastPublish = now
        features = smoothed
        matches = EmojiMatcher.rank(smoothed, limit: 12)

        if now.timeIntervalSince(lastShare) >= shareInterval {
            lastShare = now
            SharedStore.saveSnapshot(FaceSnapshot(emojis: matches.map(\.entry.emoji), date: now))
        }
    }
}

extension FaceTracker: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let face = anchors.lazy.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        let raw = FaceFeatures(blendShapes: face.blendShapes)
        let tracked = face.isTracked
        MainActor.assumeIsolated { self.ingest(raw, tracked: tracked) }
    }

    nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard anchors.contains(where: { $0 is ARFaceAnchor }) else { return }
        MainActor.assumeIsolated { self.isFaceVisible = false }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        let message = error.localizedDescription
        MainActor.assumeIsolated {
            self.isRunning = false
            self.errorMessage = message
        }
    }
}

/// Front camera feed driven by the tracker's ARSession.
struct FaceCameraView: UIViewRepresentable {
    let session: ARSession

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session = session
        view.automaticallyUpdatesLighting = false
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}
