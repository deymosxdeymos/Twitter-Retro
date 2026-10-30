import SwiftUI

package struct ClassicGroupedFormStyle: FormStyle {
    package func makeBody(configuration: Configuration) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(sections: configuration.content) { section in
                    ClassicFormSection(section: section)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .labeledContentStyle(ClassicRowLabeledContentStyle())
        .toggleStyle(.classicSwitch)
        .buttonStyle(ClassicRowButtonStyle())
        .pickerStyle(.menu)
        .tint(Color(.settingsValue))
    }
}

extension FormStyle where Self == ClassicGroupedFormStyle {
    package static var classicGrouped: ClassicGroupedFormStyle { ClassicGroupedFormStyle() }
}

private enum ClassicRow {
    static let horizontalPadding: CGFloat = 14
    static let verticalPadding: CGFloat = 8
    static let labelFont = Font.body.weight(.semibold)
}

private struct ClassicFormSection: View {
    let section: SectionConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !section.header.isEmpty {
                ForEach(section.header) { $0 }
                    .font(.headline)
                    .foregroundStyle(Color(.settingsHeaderText))
                    .shadow(color: Color(.settingsHeaderShadow), radius: 0, y: 1)
                    .padding(.horizontal, 10)
                    .padding(.top, 14)
                    .padding(.bottom, 6)
            }

            if !section.content.isEmpty {
                ClassicFormGroup(rows: section.content)
                    .padding(.top, section.header.isEmpty ? 14 : 0)
            }

            if !section.footer.isEmpty {
                ForEach(section.footer) { $0 }
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(.settingsHeaderText))
                    .shadow(color: Color(.settingsHeaderShadow), radius: 0, y: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
            }
        }
        .padding(.bottom, 8)
    }
}

private struct ClassicFormGroup: View {
    let rows: SubviewsCollection

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10)
        VStack(spacing: 0) {
            ForEach(rows) { row in
                row
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .padding(.horizontal, ClassicRow.horizontalPadding)
                    .padding(.vertical, ClassicRow.verticalPadding)
                    .contentShape(.rect)

                if row.id != rows.last?.id {
                    Color(.settingsSeparator).frame(height: 1)
                }
            }
        }
        .background(Color(.settingsGroupFill), in: shape)
        .clipShape(shape)
        .overlay { shape.strokeBorder(Color(.settingsGroupBorder)) }
        .background { shape.fill(Color(.settingsHeaderShadow).opacity(0.7)).offset(y: 1) }
    }
}

private struct ClassicRowLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(ClassicRow.labelFont)
                .foregroundStyle(.primary)

            Spacer(minLength: 12)

            configuration.content
                .foregroundStyle(Color(.settingsValue))
        }
    }
}

private struct ClassicRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ClassicRow.labelFont)
            .foregroundStyle(foreground(configuration))
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(.rect)
            .background {
                if configuration.isPressed {
                    LinearGradient(
                        colors: [Color(.rowPressedTop), Color(.rowPressedBottom)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .padding(.horizontal, -ClassicRow.horizontalPadding)
                    .padding(.vertical, -ClassicRow.verticalPadding)
                }
            }
    }

    private func foreground(_ configuration: Configuration) -> Color {
        if configuration.isPressed { return .white }
        return configuration.role == .destructive ? .red : .primary
    }
}

package struct ClassicSwitchToggleStyle: ToggleStyle {
    package func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(ClassicRow.labelFont)

            Spacer(minLength: 12)

            ClassicSwitch(isOn: configuration.$isOn)
        }
        .frame(minHeight: 44)
        .contentShape(.rect)
        .onTapGesture { configuration.isOn.toggle() }
        .sensoryFeedback(.selection, trigger: configuration.isOn)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

extension ToggleStyle where Self == ClassicSwitchToggleStyle {
    package static var classicSwitch: ClassicSwitchToggleStyle { ClassicSwitchToggleStyle() }
}

private struct ClassicSwitch: View {
    @Binding var isOn: Bool
    @State private var drag: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let width: CGFloat = 79
    private let height: CGFloat = 27
    private var travel: CGFloat { width - height }
    private var knob: CGFloat { min(max((isOn ? travel : 0) + drag, 0), travel) }
    private var motion: Animation? { reduceMotion ? nil : .spring(duration: 0.22, bounce: 0) }

    var body: some View {
        let track = Capsule()
        HStack(spacing: 0) {
            Text("ON")
                .foregroundStyle(.white)
                .shadow(color: Color(.switchOnTextShadow), radius: 0, y: -1)
                .frame(width: travel + height / 2)
                .frame(maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color(.switchOnTop), Color(.switchOnBottom)], startPoint: .top, endPoint: .bottom)
                )

            Text("OFF")
                .foregroundStyle(Color(.switchOffText))
                .shadow(color: Color(.settingsHeaderShadow), radius: 0, y: 1)
                .frame(width: travel + height / 2)
                .frame(maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color(.switchOffTop), Color(.switchOffBottom)], startPoint: .top, endPoint: .bottom)
                )
        }
        .font(.system(size: 15, weight: .bold))
        .offset(x: knob - travel)
        .frame(width: width, height: height, alignment: .leading)
        .clipShape(track)
        .overlay {
            LinearGradient(colors: [Color(.switchTrackShade), .clear], startPoint: .top, endPoint: .center)
                .clipShape(track)
                .allowsHitTesting(false)
        }
        .overlay { track.strokeBorder(Color(.switchBorder)) }
        .overlay(alignment: .leading) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(.switchKnobTop), Color(.switchKnobBottom)], startPoint: .top, endPoint: .bottom)
                )
                .overlay { Circle().strokeBorder(Color(.switchBorder)) }
                .shadow(color: Color(.switchKnobShadow), radius: 1, y: 1)
                .frame(width: height, height: height)
                .offset(x: knob)
        }
        .animation(motion, value: isOn)
        .contentShape(track)
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { drag = $0.translation.width }
                .onEnded { value in
                    let end = min(max((isOn ? travel : 0) + value.translation.width, 0), travel)
                    withAnimation(motion) {
                        drag = 0
                        isOn = end > travel / 2
                    }
                }
        )
        .accessibilityHidden(true)
    }
}
