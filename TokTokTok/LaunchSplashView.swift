import SwiftUI

/// 앱을 처음 열 때 보이는 로딩 화면(사용자 요청 2026-11-11).
/// - 기기·앱 화면 모드와 관계없이 다크(#1B1A18 + 아이보리 선). 앱 아이콘과 같은 색이다.
/// - iOS 시작 화면(Info.plist `UILaunchScreen`)은 같은 바탕색만 보여 주고, 이어서 이 화면이 뜬다.
/// - 자명종은 이미지가 아니라 벡터로 그린다(`LaunchClock`). 기종마다 화면 너비에 맞춰 앱 아이콘과 같은 구도로
///   화면 아래쪽에 놓이므로 어떤 iPhone에서도 선명하고 비율이 같다(사용자 요청: 기종별로 깨지지 않게).
/// - 위쪽에 ‘Tok Tok Tok’과 한 줄 소개를 붙인다.
struct LaunchSplashView: View {
    /// 아이콘 바탕색 #1B1A18 / 선 색 #F2EBD9
    static let background = Color(red: 0x1B / 255, green: 0x1A / 255, blue: 0x18 / 255)
    static let ivory = Color(red: 0xF2 / 255, green: 0xEB / 255, blue: 0xD9 / 255)
    static let ivoryDim = Color(red: 0xBD / 255, green: 0xB5 / 255, blue: 0xA3 / 255)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Self.background.ignoresSafeArea()

            // 화면 너비 크기의 정사각형(앱 아이콘 1024 구도)을 화면 맨 아래에 붙인다
            GeometryReader { geo in
                let side = geo.size.width
                LaunchClock(color: Self.ivory, background: Self.background)
                    .frame(width: side, height: side)
                    .position(x: side / 2, y: geo.size.height - side / 2)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                // 로딩 화면 제목만 띄어 쓴다(사용자 요청 2026-11-11). 앱 이름 표기는 TokTokTok 그대로
                Text("Tok Tok Tok")
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                    .foregroundStyle(Self.ivory)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("뒷면을 톡톡톡, 지금 시각을 남겨요")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Self.ivoryDim)
            }
            .padding(.horizontal, 28)
            .padding(.top, 40)
        }
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("TokTokTok 불러오는 중")
    }
}

/// 앱 아이콘(docs/brand/app-icon-dark.svg)과 같은 자명종 선화를 1024×1024 좌표로 그린다.
/// 그리는 영역의 크기에 맞춰 비율 그대로 확대·축소되며, 영역 밖으로 나간 부분은 잘린다.
struct LaunchClock: View {
    let color: Color
    let background: Color

    var body: some View {
        Canvas { context, size in
            var ctx = context
            ctx.scaleBy(x: size.width / 1024, y: size.height / 1024)
            // 아이콘 v8 구도: 중심 (700, 800), 왼쪽으로 15° 기울임, 1.38배
            ctx.translateBy(x: 700, y: 800)
            ctx.rotate(by: .degrees(-15))
            ctx.scaleBy(x: 1.38, y: 1.38)

            let line = StrokeStyle(lineWidth: 30, lineCap: .round, lineJoin: .round)
            let thin = StrokeStyle(lineWidth: 26, lineCap: .round, lineJoin: .round)
            let tick = StrokeStyle(lineWidth: 19, lineCap: .round, lineJoin: .round)

            // 종 두 개(왼쪽 종에는 소리 호 두 개)
            for (angle, sounds) in [(-40.0, true), (40.0, false)] {
                var bell = ctx
                bell.rotate(by: .degrees(angle))
                bell.translateBy(x: 0, y: -300)
                if sounds {
                    bell.stroke(Self.arc(radius: 165, from: 248, to: 292), with: .color(color), style: thin)
                    bell.stroke(Self.arc(radius: 215, from: 248, to: 292), with: .color(color), style: thin)
                }
                var dome = Self.arc(radius: 96, from: 180, to: 360)
                dome.closeSubpath()
                bell.stroke(dome, with: .color(color), style: line)
                bell.fill(Path(ellipseIn: CGRect(x: -13, y: -131, width: 26, height: 26)), with: .color(color))
            }

            // 타종 막대와 다리
            ctx.stroke(Self.segment(0, -270, 0, -318), with: .color(color), style: line)
            ctx.stroke(Self.segment(-150, 226, -196, 296), with: .color(color), style: line)
            ctx.stroke(Self.segment(150, 226, 196, 296), with: .color(color), style: line)

            // 몸통: 바탕색으로 채워 종 밑부분을 가린 뒤 테두리
            let body = Path(ellipseIn: CGRect(x: -266, y: -266, width: 532, height: 532))
            ctx.fill(body, with: .color(background))
            ctx.stroke(body, with: .color(color), style: line)

            // 눈금 4개
            for (x1, y1, x2, y2) in [(0.0, -208.0, 0.0, -180.0), (208, 0, 180, 0), (0, 208, 0, 180), (-208, 0, -180, 0)] {
                ctx.stroke(Self.segment(x1, y1, x2, y2), with: .color(color), style: tick)
            }

            // 바늘(10시 10분)과 가운데 축
            ctx.stroke(Self.segment(0, 0, -90, -62), with: .color(color), style: line)
            ctx.stroke(Self.segment(0, 0, 108, -100), with: .color(color), style: line)
            ctx.fill(Path(ellipseIn: CGRect(x: -19, y: -19, width: 38, height: 38)), with: .color(color))
        }
    }

    /// 화면 좌표(y가 아래로 증가)에서 각도(도)를 따라 그린 원호. 180→360은 위쪽 반원이다.
    static func arc(radius: CGFloat, from start: Double, to end: Double) -> Path {
        var path = Path()
        let steps = 48
        for i in 0...steps {
            let degree = start + (end - start) * Double(i) / Double(steps)
            let radian = degree * .pi / 180
            let point = CGPoint(x: radius * cos(radian), y: radius * sin(radian))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    static func segment(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        return path
    }
}
