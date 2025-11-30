import SwiftUI

/// A full-screen view that allows pinch-to-zoom and pan on the natal chart image
struct ZoomableChartView: View {
    let image: UIImage
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                // Zoomable image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value
                                    scale = min(max(newScale, minScale), maxScale)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    // Reset offset if zoomed out
                                    if scale <= 1.0 {
                                        withAnimation(.spring()) {
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                    // Constrain offset to prevent image from going off-screen
                                    constrainOffset(in: geometry.size)
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to zoom in/out
                        withAnimation(.spring()) {
                            if scale > 1.5 {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            } else {
                                scale = 2.5
                                lastScale = 2.5
                            }
                        }
                    }

                // Close button overlay
                VStack {
                    HStack {
                        Spacer()

                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.white.opacity(0.8))
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                )
                        }
                        .padding()
                    }

                    Spacer()

                    // Zoom indicator
                    if scale > 1.0 {
                        Text("\(Int(scale * 100))%")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Capsule())
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .statusBarHidden()
    }

    private func constrainOffset(in containerSize: CGSize) {
        let imageSize = CGSize(
            width: containerSize.width * scale,
            height: containerSize.width * scale // Assuming square chart
        )

        let maxOffsetX = max(0, (imageSize.width - containerSize.width) / 2)
        let maxOffsetY = max(0, (imageSize.height - containerSize.height) / 2)

        withAnimation(.spring()) {
            offset = CGSize(
                width: min(max(offset.width, -maxOffsetX), maxOffsetX),
                height: min(max(offset.height, -maxOffsetY), maxOffsetY)
            )
            lastOffset = offset
        }
    }
}

#Preview {
    ZoomableChartView(
        image: UIImage(systemName: "circle.hexagongrid.fill")!,
        onDismiss: {}
    )
}
