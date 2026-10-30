import SwiftUI

package struct HatchedBackdrop: View {
    package init() {}

    package var body: some View {
        Image("hash-background", bundle: .module)
            .resizable(resizingMode: .tile)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}
