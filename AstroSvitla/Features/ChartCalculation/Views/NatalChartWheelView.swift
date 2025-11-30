import SwiftUI
import Foundation
import SwiftData

struct NatalChartWheelView: View {
    let chart: NatalChart
    var allowsZoom: Bool = false
    @Environment(\.modelContext) private var modelContext

    @State private var chartImageData: Data?
    @State private var imageLoadingFailed = false
    @State private var isLoadingImage = false
    @State private var showFullScreenChart = false

    var body: some View {
        Group {
            if let imageData = chartImageData {
                if let uiImage = UIImage(data: imageData) {
                    chartImageView(uiImage: uiImage)
                } else {
                    // Image data is corrupted
                    errorPlaceholder
                }
            } else if isLoadingImage {
                // Show loading indicator while image loads
                ProgressView("Завантаження карти")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // No image available or loading failed
                errorPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .task {
            await loadChartImage()
        }
        .fullScreenCover(isPresented: $showFullScreenChart) {
            if let imageData = chartImageData, let uiImage = UIImage(data: imageData) {
                ZoomableChartView(image: uiImage) {
                    showFullScreenChart = false
                }
            }
        }
    }

    @ViewBuilder
    private func chartImageView(uiImage: UIImage) -> some View {
        if allowsZoom {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onTapGesture {
                    showFullScreenChart = true
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                        .padding(8)
                }
        } else {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }
    
    private var errorPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("Карта недоступна")
                .font(.headline)
                .foregroundStyle(.secondary)

            if imageLoadingFailed {
                Button("Повторити") {
                    Task {
                        await loadChartImage()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Image Loading

    private func loadChartImage() async {
        // Check if chart has image information
        guard let imageFileID = chart.imageFileID else {
            print("[NatalChartWheelView] No cached image metadata found")
            return
        }

        isLoadingImage = true
        imageLoadingFailed = false

        let imageCacheService = ImageCacheService()

        // Prefer PNG (faster rendering, better for display)
        if imageCacheService.imageExists(fileID: imageFileID, format: "png") {
            print("[NatalChartWheelView] Loading PNG image id=\(imageFileID)")
            do {
                let imageData = try imageCacheService.loadImage(fileID: imageFileID, format: "png")
                await MainActor.run {
                    self.chartImageData = imageData
                    self.isLoadingImage = false
                }
                print("[NatalChartWheelView] ✅ PNG loaded successfully (\(imageData.count) bytes)")
                return
            } catch {
                print("[NatalChartWheelView] Failed to load PNG: \(error)")
            }
        }

        // Fallback to SVG if PNG not available
        guard let imageFormat = chart.imageFormat else {
            await MainActor.run {
                self.imageLoadingFailed = true
                self.isLoadingImage = false
            }
            return
        }

        print("[NatalChartWheelView] Loading \(imageFormat) image id=\(imageFileID)")
        do {
            let imageData = try imageCacheService.loadImage(fileID: imageFileID, format: imageFormat)

            // For SVG, convert to PNG using the existing SVGWebViewController
            if imageFormat.lowercased() == "svg" {
                await renderSVGToPNG(svgData: imageData, imageFileID: imageFileID, imageCacheService: imageCacheService)
            } else {
                await MainActor.run {
                    self.chartImageData = imageData
                    self.isLoadingImage = false
                }
            }
            print("[NatalChartWheelView] Image loaded successfully (\(imageData.count) bytes)")
        } catch {
            await MainActor.run {
                self.imageLoadingFailed = true
                self.isLoadingImage = false
            }
            print("[NatalChartWheelView] Image load failed: \(error.localizedDescription)")
        }
    }

    /// Render SVG to PNG and cache it for future use
    @MainActor
    private func renderSVGToPNG(svgData: Data, imageFileID: String, imageCacheService: ImageCacheService) async {
        guard let svgString = String(data: svgData, encoding: .utf8) else {
            self.imageLoadingFailed = true
            self.isLoadingImage = false
            return
        }

        do {
            let controller = SVGWebViewController()
            // Extract actual SVG dimensions to preserve aspect ratio
            let dimensions = extractSVGDimensions(from: svgString)
            let renderSize = CGSize(width: 1200, height: 1200 * (dimensions.height / dimensions.width))
            
            let pngImage = try await controller.renderSVGToImage(svg: svgString, size: renderSize)

            // Cache PNG for future use
            if let pngData = pngImage.pngData() {
                try? imageCacheService.saveImage(data: pngData, fileID: imageFileID, format: "png")
                print("[NatalChartWheelView] ✅ PNG cached for future use")
                self.chartImageData = pngData
            }

            self.isLoadingImage = false
        } catch {
            print("[NatalChartWheelView] SVG to PNG conversion failed: \(error)")
            self.imageLoadingFailed = true
            self.isLoadingImage = false
        }
    }
    
    /// Extract dimensions from SVG viewBox or width/height attributes
    private func extractSVGDimensions(from svg: String) -> CGSize {
        // Try to extract viewBox first (e.g., viewBox="0 0 800 800")
        if let viewBoxRegex = try? NSRegularExpression(pattern: #"viewBox\s*=\s*"([^"]+)""#),
           let match = viewBoxRegex.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
           let viewBoxRange = Range(match.range(at: 1), in: svg) {
            let viewBoxString = String(svg[viewBoxRange])
            let values = viewBoxString.split(separator: " ").compactMap { Double($0) }
            if values.count == 4 {
                let width = values[2]
                let height = values[3]
                return CGSize(width: width, height: height)
            }
        }
        
        // Try to extract width and height attributes
        var width: Double?
        var height: Double?
        
        if let widthRegex = try? NSRegularExpression(pattern: #"width\s*=\s*"([^"]+)""#),
           let match = widthRegex.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
           let widthRange = Range(match.range(at: 1), in: svg) {
            let widthString = String(svg[widthRange]).replacingOccurrences(of: "px", with: "")
            width = Double(widthString)
        }
        
        if let heightRegex = try? NSRegularExpression(pattern: #"height\s*=\s*"([^"]+)""#),
           let match = heightRegex.firstMatch(in: svg, range: NSRange(svg.startIndex..., in: svg)),
           let heightRange = Range(match.range(at: 1), in: svg) {
            let heightString = String(svg[heightRange]).replacingOccurrences(of: "px", with: "")
            height = Double(heightString)
        }
        
        if let w = width, let h = height {
            return CGSize(width: w, height: h)
        }
        
        // Default to square if dimensions can't be extracted
        return CGSize(width: 800, height: 800)
    }
}

// MARK: - Zodiac Segment

struct ZodiacSegment: View {
    let index: Int
    let center: CGPoint
    let radius: CGFloat

    var sign: ZodiacSign {
        ZodiacSign.allCases[index]
    }

    var body: some View {
        let startAngle = Angle(degrees: Double(index) * 30 - 90)
        let endAngle = Angle(degrees: Double(index + 1) * 30 - 90)

        ZStack {
            // Segment background (pie slice)
            Path { path in
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(signColor(sign).opacity(0.1))

            // Segment border arc
            Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
            }
            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)

            // Radial line separator
            Path { path in
                path.move(to: center)
                path.addLine(to: polarToCartesian(center: center, radius: radius, angle: startAngle.degrees))
            }
            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)

            // Sign symbol
            Text(signSymbol(sign))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(signColor(sign))
                .position(
                    polarToCartesian(
                        center: center,
                        radius: radius - 15,
                        angle: startAngle.degrees + 15
                    )
                )
        }
    }

    private func signColor(_ sign: ZodiacSign) -> Color {
        switch sign.element {
        case .fire: return .red
        case .earth: return .green
        case .air: return .yellow
        case .water: return .blue
        }
    }

    private func signSymbol(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
}

// MARK: - Aspect Line

struct AspectLine: View {
    let aspect: Aspect
    let planets: [Planet]
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        guard let planet1 = planets.first(where: { $0.name == aspect.planet1 }),
              let planet2 = planets.first(where: { $0.name == aspect.planet2 }) else {
            return AnyView(EmptyView())
        }

        let angle1 = planet1.longitude - 90
        let angle2 = planet2.longitude - 90
        let point1 = polarToCartesian(center: center, radius: radius, angle: angle1)
        let point2 = polarToCartesian(center: center, radius: radius, angle: angle2)

        return AnyView(
            Path { path in
                path.move(to: point1)
                path.addLine(to: point2)
            }
            .stroke(aspectColor(aspect.type), style: StrokeStyle(lineWidth: aspectLineWidth(aspect.type), dash: aspectDash(aspect.type)))
            .opacity(0.4)
        )
    }

    private func aspectColor(_ type: AspectType) -> Color {
        switch type {
        case .conjunction: return .blue
        case .opposition: return .red
        case .trine: return .green
        case .square: return .orange
        case .sextile: return .purple
        case .quincunx: return .brown
        case .semisextile: return .cyan
        case .semisquare: return .pink
        case .sesquisquare: return .indigo
        case .quintile: return .mint
        case .biquintile: return .teal
        }
    }

    private func aspectLineWidth(_ type: AspectType) -> CGFloat {
        switch type {
        case .conjunction: return 2.5
        case .opposition: return 2.0
        case .trine: return 2.0
        case .square: return 1.5
        case .sextile: return 1.5
        case .quincunx: return 1.0
        case .semisextile: return 1.0
        case .semisquare: return 1.0
        case .sesquisquare: return 1.0
        case .quintile: return 0.8
        case .biquintile: return 0.8
        }
    }

    private func aspectDash(_ type: AspectType) -> [CGFloat] {
        switch type {
        case .conjunction: return []
        case .opposition: return []
        case .trine: return []
        case .square: return [5, 3]
        case .sextile: return [3, 2]
        case .quincunx: return [4, 4]
        case .semisextile: return [2, 3]
        case .semisquare: return [2, 2]
        case .sesquisquare: return [3, 3]
        case .quintile: return [1, 2]
        case .biquintile: return [1, 2]
        }
    }
}

// MARK: - Planet Degree Label

struct PlanetDegreeLabel: View {
    let planet: Planet
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        let angle = planet.longitude - 90
        let position = polarToCartesian(center: center, radius: radius, angle: angle)

        let degrees = Int(planet.longitude) % 30
        let minutes = Int((planet.longitude.truncatingRemainder(dividingBy: 1)) * 60)

        Text("\(degrees)°\(String(format: "%02d", minutes))'")
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(.secondary)
            .position(position)
    }
}

// MARK: - House Line

struct HouseLine: View {
    let house: House
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat

    var body: some View {
        Path { path in
            let angle = house.cusp - 90 // Adjust for 0° = East
            let start = polarToCartesian(center: center, radius: innerRadius, angle: angle)
            let end = polarToCartesian(center: center, radius: outerRadius, angle: angle)

            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(Color.primary.opacity(0.5), lineWidth: 1)
    }
}

// MARK: - House Number

struct HouseNumber: View {
    let house: House
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        let nextCusp = house.cusp + 30 // Approximate
        let midAngle = (house.cusp + nextCusp) / 2 - 90

        Text("\(house.number)")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .position(polarToCartesian(center: center, radius: radius, angle: midAngle))
    }
}

// MARK: - Planet Marker

struct PlanetMarker: View {
    let planet: Planet
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        let angle = planet.longitude - 90
        let position = polarToCartesian(center: center, radius: radius, angle: angle)

        ZStack {
            Circle()
                .fill(planetColor(planet.name))
                .frame(width: 24, height: 24)

            Text(planetSymbol(planet.name))
                .font(.system(size: 14))
                .foregroundStyle(.white)

            if planet.isRetrograde {
                Text("℞")
                    .font(.system(size: 8))
                    .foregroundStyle(.white)
                    .offset(x: 10, y: -8)
            }
        }
        .position(position)
    }

    private func planetSymbol(_ planet: PlanetType) -> String {
        switch planet {
        case .sun: return "☉"
        case .moon: return "☽"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        case .trueNode: return "☊"  // North Node symbol
        case .southNode: return "☋"  // South Node symbol
        case .lilith: return "⚸"  // Lilith symbol
        }
    }

    private func planetColor(_ planet: PlanetType) -> Color {
        switch planet {
        case .sun: return .orange
        case .moon: return .gray
        case .mercury: return .yellow
        case .venus: return .pink
        case .mars: return .red
        case .jupiter: return .purple
        case .saturn: return .brown
        case .uranus: return .cyan
        case .neptune: return .blue
        case .pluto: return .indigo
        case .trueNode: return .green  // North Node color
        case .southNode: return .mint  // South Node color
        case .lilith: return .purple.opacity(0.8)  // Lilith color
        }
    }
}

// MARK: - Ascendant Marker

struct AscendantMarker: View {
    let degree: Double
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        let angle = degree - 90
        let position = polarToCartesian(center: center, radius: radius + 15, angle: angle)

        Text("ASC")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.blue)
            .position(position)
    }
}

// MARK: - Midheaven Marker

struct MidheavenMarker: View {
    let degree: Double
    let center: CGPoint
    let radius: CGFloat

    var body: some View {
        let angle = degree - 90
        let position = polarToCartesian(center: center, radius: radius + 15, angle: angle)

        Text("MC")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.green)
            .position(position)
    }
}

// MARK: - Helper Functions

private func polarToCartesian(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
    let radians = CGFloat(angle * .pi / 180)
    return CGPoint(
        x: center.x + radius * cos(radians),
        y: center.y + radius * sin(radians)
    )
}

// MARK: - Preview

#Preview {
    NatalChartWheelView(
        chart: NatalChart(
            birthDate: Date(),
            birthTime: Date(),
            latitude: 50.4501,
            longitude: 30.5234,
            locationName: "Kyiv",
            planets: [
                Planet(id: UUID(), name: .sun, longitude: 287.5, latitude: 0, sign: .capricorn, house: 6, isRetrograde: false, speed: 1.0),
                Planet(id: UUID(), name: .moon, longitude: 123.2, latitude: 0, sign: .cancer, house: 12, isRetrograde: false, speed: 13.0),
                Planet(id: UUID(), name: .mercury, longitude: 275.3, latitude: 0, sign: .capricorn, house: 6, isRetrograde: true, speed: 0.5),
            ],
            houses: (1...12).map { House(id: UUID(), number: $0, cusp: Double($0 - 1) * 30, sign: ZodiacSign.allCases[($0 - 1) % 12]) },
            aspects: [],
            houseRulers: [],
            ascendant: 127.5,
            midheaven: 215.3,
            calculatedAt: Date()
        )
    )
    .padding()
    .background(Color(.systemBackground))
}
