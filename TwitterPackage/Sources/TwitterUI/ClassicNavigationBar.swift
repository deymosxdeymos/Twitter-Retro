import SwiftUI

/// A modal's silver bar. Slots keep Cancel, Drafts and Tweet as real buttons rather than painted chrome.
package struct ClassicNavigationBar<Leading: View, Trailing: View>: View {
    let title: LocalizedStringKey
    let leading: Leading
    let trailing: Trailing

    package init(
        _ title: LocalizedStringKey,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    package var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                leading
                Spacer(minLength: 8)
                Text(title)
                    .font(.headline)
                    .letterpress()
                    .fixedSize()
                Spacer(minLength: 8)
                trailing
            }

            VStack(spacing: 4) {
                Text(title).font(.headline).letterpress()
                HStack {
                    leading
                    Spacer(minLength: 8)
                    trailing
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background { ClassicColumnBarBackdrop() }
        .accessibilityElement(children: .contain)
    }
}

package struct ClassicBackButtonStyle: ButtonStyle {
    package init() {}

    package func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(Color(.buttonText))
            .shadow(color: Color(.fieldWellHighlight), radius: 0, y: 1)
            .padding(.leading, 18)
            .padding(.trailing, 12)
            .frame(minHeight: 44)
            .background {
                Image(configuration.isPressed ? "ButtonPressed" : "ButtonDefault", bundle: .module)
                    .resizable(capInsets: EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5))
                    .clipShape(BackBezel())
                    .overlay { BackBezel().stroke(Color(.fieldWellBorderTop), lineWidth: 0.5) }
                    .padding(.vertical, 5)
            }
            .contentShape(.rect)
    }
}

private struct BackBezel: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX + 11, y: rect.minY + 2))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + 15, y: rect.minY), control: CGPoint(x: rect.minX + 12, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - 4, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + 4), control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 4))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - 4, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + 15, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + 11, y: rect.maxY - 2), control: CGPoint(x: rect.minX + 12, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
