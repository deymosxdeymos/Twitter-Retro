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
        .background { ClassicPinstripes().ignoresSafeArea() }
        .labeledContentStyle(ClassicRowLabeledContentStyle())
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
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

private struct ClassicPinstripes: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(.settingsBackground)))
            var x: CGFloat = 0
            while x < size.width {
                context.fill(Path(CGRect(x: x, y: 0, width: 3, height: size.height)), with: .color(Color(.settingsStripe)))
                x += 7
            }
        }
        .accessibilityHidden(true)
    }
}
