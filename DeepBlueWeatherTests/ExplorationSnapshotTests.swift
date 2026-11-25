//
//  ExplorationSnapshotTests.swift
//  DeepBlueWeatherTests
//
//  Renders the design explorations in a real simulator window (so shaders and
//  charts draw exactly as on screen). Skipped unless TEST_RUNNER_DESIGN_DIR is set.
//

import XCTest
import SwiftUI
@testable import DeepBlueWeather

@MainActor
final class ExplorationSnapshotTests: XCTestCase {

    func testRenderVariants() async throws {
        guard let dir = ProcessInfo.processInfo.environment["DESIGN_DIR"] else {
            throw XCTSkip("Set TEST_RUNNER_DESIGN_DIR to render the design explorations.")
        }
        let folder = URL(fileURLWithPath: dir)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let scenarios: [(String, ConditionsSnapshot)] = [("calm", .calm), ("rough", .rough), ("night", .night)]
        for (scenario, data) in scenarios {
            for style in [UIUserInterfaceStyle.light, .dark] {
                let mode = style == .dark ? "dark" : "light"
                var shots: [(String, UIImage)] = []
                let variants: [(String, AnyView)] = [
                    ("A · Living ocean", AnyView(ConditionsVariantA(data: data))),
                    ("B · Logbook", AnyView(ConditionsVariantB(data: data))),
                    ("C · Above / below", AnyView(ConditionsVariantC(data: data)))
                ]
                for (name, view) in variants {
                    let image = try await render(ExplorationFrame { view }, style: style)
                    shots.append((name, image))
                    try image.pngData()?.write(to: folder.appendingPathComponent("\(name.prefix(1))-\(scenario)-\(mode).png"))
                }
                // Whole page, for the scenarios used in the overview.
                if (scenario == "calm" && style == .light) || (scenario == "night" && style == .dark) {
                    var full: [(String, UIImage)] = []
                    for (name, view) in variants {
                        full.append((name, try await render(ExplorationFrame { view }, style: style, height: 1500)))
                    }
                    try sheet(full, title: "\(scenario.capitalized) · \(mode) · full page", dark: style == .dark)
                        .pngData()?.write(to: folder.appendingPathComponent("full-\(scenario)-\(mode).png"))
                }
                try sheet(shots, title: "\(scenario.capitalized) · \(mode)", dark: style == .dark)
                    .pngData()?.write(to: folder.appendingPathComponent("compare-\(scenario)-\(mode).png"))
            }
        }
    }

    private func render(_ view: some View, style: UIUserInterfaceStyle, height: CGFloat? = nil) async throws -> UIImage {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.overrideUserInterfaceStyle = style
        if let height { window.frame.size.height = height }
        window.rootViewController = UIHostingController(rootView: view)
        window.windowLevel = .alert + 1
        window.makeKeyAndVisible()
        try await Task.sleep(for: .seconds(2.2))
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        window.isHidden = true
        return image
    }

    private func sheet(_ shots: [(String, UIImage)], title: String, dark: Bool) -> UIImage {
        let size = shots[0].1.size
        let gap: CGFloat = 28, header: CGFloat = 78
        let canvas = CGSize(width: size.width * 3 + gap * 4, height: size.height + header + gap)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        let ink: UIColor = dark ? .white : .black
        return UIGraphicsImageRenderer(size: canvas, format: format).image { context in
            (dark ? UIColor(white: 0.17, alpha: 1) : UIColor(white: 0.84, alpha: 1)).setFill()
            context.fill(CGRect(origin: .zero, size: canvas))
            title.draw(at: CGPoint(x: gap, y: 10),
                       withAttributes: [.font: UIFont.systemFont(ofSize: 17, weight: .medium), .foregroundColor: ink])
            for (i, shot) in shots.enumerated() {
                let x = gap + CGFloat(i) * (size.width + gap)
                shot.0.draw(at: CGPoint(x: x, y: 40),
                            withAttributes: [.font: UIFont.systemFont(ofSize: 24, weight: .bold), .foregroundColor: ink])
                let rect = CGRect(origin: CGPoint(x: x, y: header), size: size)
                context.cgContext.saveGState()
                UIBezierPath(roundedRect: rect, cornerRadius: 44).addClip()
                shot.1.draw(in: rect)
                context.cgContext.restoreGState()
            }
        }
    }
}
