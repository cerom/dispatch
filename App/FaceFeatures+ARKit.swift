import ARKit

extension FaceFeatures {
    /// Maps ARKit's 52 blend shapes onto our expression features.
    /// Raw blend shapes rarely reach 1.0, so each feature gets a gain (the value that should read as "full").
    init(blendShapes s: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        func v(_ key: ARFaceAnchor.BlendShapeLocation) -> Double { s[key]?.doubleValue ?? 0 }
        func gain(_ x: Double, full: Double) -> Double { min(x / full, 1) }
        func avg(_ a: Double, _ b: Double) -> Double { (a + b) / 2 }

        let smileL = v(.mouthSmileLeft), smileR = v(.mouthSmileRight)
        let blinkL = v(.eyeBlinkLeft), blinkR = v(.eyeBlinkRight)
        let browOutL = v(.browOuterUpLeft), browOutR = v(.browOuterUpRight)

        self.init()
        self[.smile] = gain(avg(smileL, smileR), full: 0.8)
        self[.frown] = gain(avg(v(.mouthFrownLeft), v(.mouthFrownRight)), full: 0.5)
        self[.jawOpen] = gain(v(.jawOpen), full: 0.7)
        self[.eyesClosed] = gain(min(blinkL, blinkR), full: 0.8)
        self[.wink] = gain(abs(blinkL - blinkR), full: 0.6)
        self[.eyesWide] = gain(avg(v(.eyeWideLeft), v(.eyeWideRight)), full: 0.6)
        self[.squint] = gain(avg(v(.eyeSquintLeft), v(.eyeSquintRight)), full: 0.7)
        self[.browUp] = gain(max(v(.browInnerUp), avg(browOutL, browOutR)), full: 0.8)
        self[.browDown] = gain(avg(v(.browDownLeft), v(.browDownRight)), full: 0.7)
        self[.browRaise] = gain(abs(browOutL - browOutR), full: 0.5)
        self[.pucker] = gain(max(v(.mouthPucker), v(.mouthFunnel)), full: 0.8)
        self[.cheekPuff] = gain(v(.cheekPuff), full: 0.6)
        self[.tongueOut] = gain(v(.tongueOut), full: 0.5)
        self[.sneer] = gain(avg(v(.noseSneerLeft), v(.noseSneerRight)), full: 0.6)
        self[.smirk] = gain(abs(smileL - smileR), full: 0.5)
        self[.grimace] = gain(avg(v(.mouthStretchLeft), v(.mouthStretchRight)), full: 0.6)
    }
}
