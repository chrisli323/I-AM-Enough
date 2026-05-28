//
//  SplashView.swift
//  I AM Enough
//

import SwiftUI

struct SplashView: View {
    @State private var breathing = false
    @State private var finished = false

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("Splash")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            GeometryReader { geo in
                VStack(alignment: .leading, spacing: 3) {
                    Text("One Teaching.")
                    Text("One Day at a Time.")
                }
                .font(Theme.display(min(geo.size.width * 0.076, 31)))
                .foregroundStyle(Theme.inkFadedDark)
                .shadow(color: Theme.inkFadedDark.opacity(0.14),
                        radius: 0.8,
                        x: 0.4,
                        y: 0.8)
                .padding(.leading, 40)
                .padding(.top, max(geo.safeAreaInsets.top + 42, 72))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .allowsHitTesting(false)

            ZStack {
                SplashLogoView()
                    .frame(width: 226, height: 226)

                SerpentRingView()
                    .frame(width: 284, height: 284)
            }
            .offset(y: 32)
            .scaleEffect(breathing ? 1.04 : 0.94)
            .opacity(breathing ? 1.0 : 0.60)
            .shadow(
                color: Color.orange.opacity(breathing ? 0.35 : 0.0),
                radius: breathing ? 16 : 0
            )
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathing)
        }
        .opacity(finished ? 0 : 1)
        .task {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                breathing = true
            }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeIn(duration: 0.5)) { finished = true }
            try? await Task.sleep(for: .seconds(0.5))
            onFinished()
        }
    }
}

// MARK: - Native SwiftUI logo (no background — parchment shows through)

private struct SplashLogoView: View {
    private let ink = Color(red: 0.231, green: 0.149, blue: 0.067)
    private let sunYellow = Color(red: 1.0, green: 0.824, blue: 0.0)

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)

            ZStack {
                // Sun rays + body drawn on a transparent canvas
                Canvas { ctx, sz in
                    let cx = sz.width / 2
                    let cy = sz.height / 2
                    let sunR    = s * 0.283
                    let bodyR   = s * 0.288   // rays start just outside sun
                    let tipR    = s * 0.479
                    let numRays = 16
                    let halfGap = Double.pi / Double(numRays) * 0.52
                    let yellow  = Color(red: 1.0, green: 0.824, blue: 0.0)

                    // Rays
                    for i in 0..<numRays {
                        let a    = Double(i) * (2 * .pi / Double(numRays)) - .pi / 2
                        let tipX = cx + tipR  * cos(a);    let tipY = cy + tipR  * sin(a)
                        let blX  = cx + bodyR * cos(a - halfGap); let blY = cy + bodyR * sin(a - halfGap)
                        let brX  = cx + bodyR * cos(a + halfGap); let brY = cy + bodyR * sin(a + halfGap)
                        var p = Path()
                        p.move(to: CGPoint(x: tipX, y: tipY))
                        p.addLine(to: CGPoint(x: blX, y: blY))
                        p.addLine(to: CGPoint(x: brX, y: brY))
                        p.closeSubpath()
                        ctx.fill(p, with: .color(yellow))
                    }

                    // Sun body
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - sunR, y: cy - sunR, width: sunR * 2, height: sunR * 2)),
                        with: .color(yellow)
                    )
                }

                // "I AM" — above center
                Text("I AM")
                    .font(.custom("Georgia-Bold", size: s * 0.21))
                    .foregroundColor(ink)
                    .fixedSize()
                    .offset(y: -s * 0.07)

                // "Enough" — fixedSize collapses Zapfino's oversized frame
                ZStack {
                    Text("Enough").font(.custom("Zapfino", size: s * 0.105)).foregroundColor(ink).offset(x: 1)
                    Text("Enough").font(.custom("Zapfino", size: s * 0.105)).foregroundColor(ink)
                }
                .fixedSize()
                .offset(y: s * 0.17)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

// MARK: - Serpent ring — yellow with orange glow outline

private struct SerpentRingView: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.82)
            .stroke(
                AngularGradient(
                    stops: [
                        .init(color: .clear,                                        location: 0.00),
                        .init(color: Color.yellow.opacity(0.35),                    location: 0.20),
                        .init(color: Color(red: 1.0, green: 0.85, blue: 0.0),       location: 0.82),
                        .init(color: Color(red: 1.0, green: 0.85, blue: 0.0),       location: 1.00),
                    ],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 13, lineCap: .round)
            )
            .shadow(color: Color.orange.opacity(0.75), radius: 4, x: 0, y: 0)
            .rotationEffect(.degrees(rotation - 90))
            .onAppear {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
