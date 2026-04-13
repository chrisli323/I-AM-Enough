//
//  Theme.swift
//  I AM Sober
//
//  Design tokens for the parchment / wisdom-scroll aesthetic.
//
//  Fonts use Apple's built-in `.serif` design (New York), which is Apple's
//  system serif designed specifically for long-form reading on iOS. This
//  gives us the "wise old book" feel without bundling external fonts and
//  with perfect HIG / Dynamic Type compliance.
//

import SwiftUI
import UIKit

enum Theme {

    // MARK: - Colors

    /// Lightest cream — top of the parchment background gradient.
    static let parchmentLight = Color(uiColor: UIColor(red: 0.969, green: 0.937, blue: 0.851, alpha: 1)) // #F7EFD9
    /// Slightly darker, warmer cream — bottom of the gradient.
    static let parchmentDark = Color(uiColor: UIColor(red: 0.929, green: 0.871, blue: 0.737, alpha: 1))  // #EDDEBC
    /// A barely-there warm shadow used for the page edges.
    static let parchmentShadow = Color(uiColor: UIColor(red: 0.749, green: 0.620, blue: 0.376, alpha: 1)) // #BF9E60

    /// Primary "ink" color for body copy — a deep walnut brown that reads
    /// almost as black on parchment but feels warmer than pure #000.
    static let ink = Color(uiColor: UIColor(red: 0.231, green: 0.149, blue: 0.067, alpha: 1)) // #3B2611
    /// Secondary ink — used for headers, dividers, and the reflection text.
    static let inkSecondary = Color(uiColor: UIColor(red: 0.435, green: 0.314, blue: 0.149, alpha: 1)) // #6F5026
    /// Faded ink — for small caps labels and the most subtle elements.
    static let inkFaded = Color(uiColor: UIColor(red: 0.580, green: 0.451, blue: 0.247, alpha: 1)) // #94733F

    /// A warm gold accent for ornaments and dividers.
    static let accentGold = Color(uiColor: UIColor(red: 0.690, green: 0.529, blue: 0.275, alpha: 1)) // #B08746

    // MARK: - Background

    /// The full parchment surface: warm gradient + subtle aged-edges
    /// vignette + a fine paper-grain noise texture + soft inner shadows
    /// at all four edges. Used as the root background of the teaching
    /// view. All layers are non-interactive.
    static var parchmentBackground: some View {
        ZStack {
            LinearGradient(
                colors: [parchmentLight, parchmentDark],
                startPoint: .top,
                endPoint: .bottom
            )

            // Aged-paper radial vignette — center is brightest, edges
            // pick up a faint warm shadow.
            RadialGradient(
                colors: [Color.clear, parchmentShadow.opacity(0.20)],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )

            PaperGrain()

            PageEdgeShadow()
        }
        .ignoresSafeArea()
    }

    // MARK: - Fonts

    /// Body text — generous, serif, optimized for long-form reading.
    static func body(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    /// Italic body — used for the reflection prompt.
    static func bodyItalic(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .regular, design: .serif).italic()
    }

    /// Display heading — used for the "Day N" label.
    static func display(_ size: CGFloat = 38) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    /// Small caps style label — used for the date and section markers.
    static func smallCaps(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    // MARK: - Spacing

    static let pageHorizontalPadding: CGFloat = 32
    static let bodyLineSpacing: CGFloat = 9
    static let reflectionLineSpacing: CGFloat = 6
}

// MARK: - Paper grain

/// A fine, deterministic noise texture that gives the parchment a tactile
/// "real paper" quality. Drawn once via Canvas with a seeded RNG so the
/// pattern is stable across redraws and across launches. Tuned for low
/// density / low opacity so it never competes with the text.
private struct PaperGrain: View {
    var body: some View {
        Canvas { context, size in
            var rng = SeededRandomNumberGenerator(seed: 0xC0FFEE_BEEF_F00D)
            // Number of specks scales with screen area.
            let count = Int(size.width * size.height * 0.018)
            for _ in 0..<count {
                let x = Double(rng.next() % 10_000) / 10_000.0 * size.width
                let y = Double(rng.next() % 10_000) / 10_000.0 * size.height
                let alpha = 0.06 + Double(rng.next() % 1_000) / 1_000.0 * 0.18
                let radius = 0.35 + Double(rng.next() % 1_000) / 1_000.0 * 0.85
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.black.opacity(alpha))
                )
            }
        }
        .blendMode(.multiply)
        .allowsHitTesting(false)
        .drawingGroup() // rasterise once for performance
    }
}

/// xorshift64 — small, fast, deterministic. Lets us draw the same speck
/// pattern every render so the grain never shimmers.
private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed != 0 ? seed : 0xDEADBEEF }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Page edge shadow

/// Soft inner shadows on all four edges. Reinforces the "this is a page"
/// feel and gives the content a subtle inset, like text printed on a real
/// sheet of paper rather than glowing on a screen.
private struct PageEdgeShadow: View {
    var body: some View {
        ZStack {
            // Top
            LinearGradient(
                colors: [Theme.parchmentShadow.opacity(0.32), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 90)
            .frame(maxHeight: .infinity, alignment: .top)

            // Bottom
            LinearGradient(
                colors: [.clear, Theme.parchmentShadow.opacity(0.32)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 90)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Left
            LinearGradient(
                colors: [Theme.parchmentShadow.opacity(0.22), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 36)
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right
            LinearGradient(
                colors: [.clear, Theme.parchmentShadow.opacity(0.22)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 36)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .blendMode(.multiply)
        .allowsHitTesting(false)
    }
}
