import SwiftUI

struct LiveScanGuideView: View {
    @ObservedObject var cameraManager: CameraManager
    let instruction: String
    var guideWidth: CGFloat = 170
    var isVisible = true
    var fontScale: CGFloat = 1
    var isBoldText = false

    @State private var offset: CGSize = .zero
    @State private var dragOrigin: CGSize?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.8), lineWidth: 2)
                    .frame(width: guideWidth, height: 270)
                Text(instruction)
                    .font(.system(size: 14 * fontScale, weight: isBoldText ? .bold : .medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .glassEffect(.regular, in: Capsule())
            }
            .contentShape(Rectangle())
            .gesture(dragGesture(in: geometry.size))
            .position(guidePosition(in: geometry.size))
            .onChange(of: cameraManager.liveDetectedTextBox) { _, box in
                guard let box else { return }
                let point = CGPoint(x: box.midX * geometry.size.width,
                                    y: (1 - box.midY) * geometry.size.height)
                withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.9)) {
                    offset = clampedOffset(for: point, in: geometry.size)
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.18), value: isVisible)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
        .onAppear { cameraManager.isLiveGuideTrackingEnabled = isVisible }
        .onChange(of: isVisible) { _, visible in cameraManager.isLiveGuideTrackingEnabled = visible }
        .accessibilityHint("The guide follows detected numbers. You can also drag it.")
    }

    private func guidePosition(in size: CGSize) -> CGPoint {
        let base = basePosition(in: size)
        return CGPoint(x: base.x + offset.width, y: base.y + offset.height)
    }

    private func basePosition(in size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2, y: min(max(180, size.height * 0.27), size.height * 0.45))
    }

    private func clampedOffset(for point: CGPoint, in size: CGSize) -> CGSize {
        let base = basePosition(in: size)
        return clamp(CGSize(width: point.x - base.x, height: point.y - base.y), in: size)
    }

    private func clamp(_ value: CGSize, in size: CGSize) -> CGSize {
        let base = basePosition(in: size)
        let halfWidth = guideWidth / 2 + 10
        let halfHeight: CGFloat = 160
        let minX = halfWidth + 12 - base.x
        let maxX = size.width - halfWidth - 12 - base.x
        let minY: CGFloat = 185 - base.y
        let maxY = size.height - 165 - halfHeight - base.y
        let x = maxX < minX ? 0 : min(max(value.width, minX), maxX)
        let y = maxY < minY ? 0 : min(max(value.height, minY), maxY)
        return CGSize(width: x, height: y)
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if dragOrigin == nil {
                    dragOrigin = offset
                    cameraManager.isLiveGuideTrackingEnabled = false
                }
                let origin = dragOrigin ?? .zero
                offset = clamp(CGSize(width: origin.width + value.translation.width,
                                      height: origin.height + value.translation.height), in: size)
            }
            .onEnded { _ in
                dragOrigin = nil
                cameraManager.isLiveGuideTrackingEnabled = isVisible
            }
    }
}
