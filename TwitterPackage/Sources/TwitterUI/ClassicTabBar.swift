import SwiftUI

/// The original tab artwork in a horizontal bar, with its background extending under the home indicator.
package struct ClassicTabBar<ID: Hashable>: View {
    let tabs: [ClassicSidebarTab<ID>]
    @Binding var selection: ID
    let reselect: (ID) -> Void

    package init(tabs: [ClassicSidebarTab<ID>], selection: Binding<ID>, reselect: @escaping (ID) -> Void) {
        self.tabs = tabs
        _selection = selection
        self.reselect = reselect
    }

    package var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button {
                    if tab.id == selection {
                        reselect(tab.id)
                    } else {
                        selection = tab.id
                    }
                } label: {
                    tab.icon.image(isSelected: tab.id == selection)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(alignment: .bottom) {
                            if tab.id == selection {
                                Image("TabGlow", bundle: .module)
                                    .offset(y: 8)
                                    .accessibilityHidden(true)
                            }
                        }
                        .background {
                            if tab.id == selection {
                                Image("TabSelected", bundle: .module)
                                    .resizable()
                                    .accessibilityHidden(true)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if tab.badgeCount > 0 {
                                Text(tab.badgeCount > 99 ? "99+" : tab.badgeCount.formatted())
                                    .font(.caption2.bold().monospacedDigit())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 4)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(.red, in: .capsule)
                                    .dynamicTypeSize(.large)
                                    .padding(.trailing, 8)
                                    .padding(.top, 2)
                                    .accessibilityHidden(true)
                            }
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityValue(tab.badgeCount > 0 ? "\(tab.badgeCount) unread" : "")
                .accessibilityAddTraits(tab.id == selection ? .isSelected : [])
            }
        }
        .frame(height: 50)
        .background {
            Image("SidebarBackground", bundle: .module)
                .resizable()
                .ignoresSafeArea(.container, edges: [.bottom, .horizontal])
                .accessibilityHidden(true)
        }
        .overlay(alignment: .top) {
            Color.black.frame(height: 1).allowsHitTesting(false)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}
