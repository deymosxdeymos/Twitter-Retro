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
        .pickerStyle(.menu)
        .tint(Color(.settingsValue))
    }
}

extension FormStyle where Self == ClassicGroupedFormStyle {
    package static var classicGrouped: ClassicGroupedFormStyle { ClassicGroupedFormStyle() }
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
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
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 12)

            configuration.content
                .foregroundStyle(Color(.settingsValue))
        }
    }
}

package struct ClassicSwitchToggleStyle: ToggleStyle {
    package func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.body.weight(.semibold))

            Spacer(minLength: 12)

            ClassicSwitch(isOn: configuration.$isOn)
        }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let width: CGFloat = 79
    private let height: CGFloat = 27
    private var travel: CGFloat { width - height }

    var body: some View {
        let track = Capsule()
        HStack(spacing: 0) {
            Text("ON")
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 0, y: -1)
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
        .offset(x: isOn ? 0 : -travel)
        .frame(width: width, height: height, alignment: .leading)
        .clipShape(track)
        .overlay {
            LinearGradient(colors: [.black.opacity(0.25), .clear], startPoint: .top, endPoint: .center)
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
                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                .frame(width: height, height: height)
                .offset(x: isOn ? travel : 0)
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: isOn)
        .contentShape(track)
        .onTapGesture { isOn.toggle() }
        .sensoryFeedback(.selection, trigger: isOn)
    }
}
