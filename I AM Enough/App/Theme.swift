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
    //
    //  Every color uses a UIColor trait-collection block so it automatically
    //  adapts between the light parchment theme and the sepia dark theme.
    //  Light values are unchanged from Phase 2; dark values use a deep warm-
    //  leather palette — dark brown backgrounds, warm cream text, bright gold
    //  accents — so the app feels like reading by candlelight.

    /// Lightest cream (light) / deep warm leather (dark) — top of gradient.
    static let parchmentLight = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.08, blue: 0.04, alpha: 1)  // #1C1409
            : UIColor(red: 0.969, green: 0.937, blue: 0.851, alpha: 1) // #F7EFD9
    })
    /// Slightly darker cream (light) / near-black sepia (dark) — bottom of gradient.
    static let parchmentDark = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.05, blue: 0.02, alpha: 1)  // #120D05
            : UIColor(red: 0.929, green: 0.871, blue: 0.737, alpha: 1) // #EDDEBC
    })
    /// Edge shadow hue — warm tan (light) / deep sepia black (dark).
    static let parchmentShadow = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.02, blue: 0.01, alpha: 1)  // #0A0603
            : UIColor(red: 0.749, green: 0.620, blue: 0.376, alpha: 1) // #BF9E60
    })

    /// Primary "ink" — walnut brown (light) / warm parchment cream (dark).
    static let ink = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.87, blue: 0.74, alpha: 1)  // #EDE0BD
            : UIColor(red: 0.231, green: 0.149, blue: 0.067, alpha: 1) // #3B2611
    })
    /// Secondary ink — medium brown (light) / golden tan (dark).
    /// Darkened from #6F5026 → #523018 for contrast on the parchment texture.
    static let inkSecondary = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.78, green: 0.68, blue: 0.51, alpha: 1)  // #C7AD83
            : UIColor(red: 0.322, green: 0.188, blue: 0.094, alpha: 1) // #523018
    })
    /// Faded ink — warm dark brown (light) / muted gold (dark).
    /// Darkened from #94733F → #6B4A24 for contrast on the parchment texture.
    static let inkFaded = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.63, green: 0.54, blue: 0.38, alpha: 1)  // #A18A61
            : UIColor(red: 0.420, green: 0.290, blue: 0.141, alpha: 1) // #6B4A24
    })
    /// Faded ink darkened — used for Day N header and selected tab icon.
    static let inkFadedDark = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.84, green: 0.72, blue: 0.52, alpha: 1)  // #D6B884 — bright warm gold on dark
            : UIColor(red: 0.34, green: 0.26, blue: 0.14, alpha: 1) // #574224
    })

    /// Warm gold accent — ornaments and dividers.
    static let accentGold = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.75, green: 0.58, blue: 0.32, alpha: 1)  // #BF9452 — slightly brighter in dark
            : UIColor(red: 0.690, green: 0.529, blue: 0.275, alpha: 1) // #B08746
    })

    // MARK: - Background

    /// The full parchment surface — rendered from the bundled parchmentBG
    /// image asset so every screen matches the App Store screenshots exactly.
    /// GeometryReader pins the image to the exact screen size so it never
    /// affects the ZStack layout of the views placed on top of it.
    static var parchmentBackground: some View {
        GeometryReader { geo in
            Image("parchmentBG")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
    @Environment(\.colorScheme) private var colorScheme

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
                    with: .color(.white.opacity(alpha))
                )
            }
        }
        // Multiply darkens on parchment; screen lightens on the dark leather bg.
        .blendMode(colorScheme == .dark ? .screen : .multiply)
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
