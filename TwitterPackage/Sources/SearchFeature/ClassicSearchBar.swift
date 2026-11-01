import SwiftUI
import TwitterUI

/// iPhone OS's `UISearchBar`: a blue-grey strip with a white, fully rounded field, a magnifying glass, a clear button
/// while there's text, the bookmark button for saving the search, and Cancel while typing.
struct ClassicSearchBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    /// Whether the search in the field is saved; nil when there's nothing to save yet.
    let isSaved: Bool?
    let submit: () -> Void
    let toggleSaved: () -> Void
    let cancel: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(white: 0.45))
                    .accessibilityHidden(true)

                TextField("Search", text: $text, prompt: Text("Search").foregroundStyle(Color(white: 0.6)))
                    .focused(isFocused)
                    .submitLabel(.search)
                    .onSubmit(submit)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.black)
                    .tint(.twitterBlue)

                if isFocused.wrappedValue, !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(white: 0.6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear Text")
                } else if let isSaved {
                    Button(action: toggleSaved) {
                        Image(systemName: isSaved ? "book.fill" : "book")
                            .foregroundStyle(isSaved ? Color.twitterBlue : Color(white: 0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSaved ? "Remove Saved Search" : "Save Search")
                }
            }
            .font(.body)
            .padding(.horizontal, 10)
            .frame(minHeight: 32)
            .background {
                Capsule()
                    .fill(.white)
                    .overlay {
                        // The field's inner shadow along its top edge.
                        Capsule()
                            .stroke(Color.black.opacity(0.35), lineWidth: 1)
                            .blur(radius: 0.6)
                            .offset(y: 1)
                            .mask(Capsule())
                    }
                    .overlay { Capsule().stroke(Color(white: 0.45), lineWidth: 0.5) }
            }
            .contentShape(.capsule)
            .onTapGesture { isFocused.wrappedValue = true }

            if isFocused.wrappedValue {
                Button("Cancel", action: cancel)
                    .buttonStyle(SearchBarButtonStyle())
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            LinearGradient(colors: barColors, startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .top) { Color.white.opacity(0.35).frame(height: 1) }
                .overlay(alignment: .bottom) { Color(red: 0.3, green: 0.35, blue: 0.42).frame(height: 1) }
        }
        .animation(.snappy(duration: 0.2), value: isFocused.wrappedValue)
    }

    private var barColors: [Color] {
        colorScheme == .dark
            ? [Color(red: 0.27, green: 0.29, blue: 0.32), Color(red: 0.16, green: 0.17, blue: 0.19)]
            : [Color(red: 0.80, green: 0.84, blue: 0.88), Color(red: 0.64, green: 0.69, blue: 0.76)]
    }
}

/// The search bar's own bordered button, tinted with the bar: darker blue-grey glass, white bold text.
private struct SearchBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 0, y: -1)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color(red: 0.55, green: 0.61, blue: 0.69), Color(red: 0.42, green: 0.48, blue: 0.57)],
                        startPoint: .top, endPoint: .bottom)
                    LinearGradient(
                        colors: [Color(red: 0.33, green: 0.39, blue: 0.48), Color(red: 0.38, green: 0.44, blue: 0.53)],
                        startPoint: .top, endPoint: .bottom)
                }
                .brightness(configuration.isPressed ? -0.1 : 0)
                .clipShape(shape)
                .overlay { shape.stroke(Color(red: 0.2, green: 0.24, blue: 0.3), lineWidth: 1) }
            }
            // 30 pt drawn, as the bar's buttons were; the touch area reaches the bar's full height.
            .contentShape(.rect.inset(by: -7))
    }
}

/// A plain table's section header from iPhone OS: a grey-blue gradient band with white, shadowed bold text.
struct ClassicPlainHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var trailing: Trailing
    @Environment(\.colorScheme) private var colorScheme

    init(_ title: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            trailing
                .font(.footnote.weight(.semibold))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 0, y: 1)
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, minHeight: 24)
        .background {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .top) { Color.white.opacity(0.25).frame(height: 1) }
                .overlay(alignment: .bottom) { Color.black.opacity(0.15).frame(height: 1) }
        }
    }

    private var colors: [Color] {
        colorScheme == .dark
            ? [Color(red: 0.30, green: 0.33, blue: 0.37), Color(red: 0.22, green: 0.24, blue: 0.27)]
            : [Color(red: 0.62, green: 0.67, blue: 0.72), Color(red: 0.53, green: 0.59, blue: 0.65)]
    }
}
