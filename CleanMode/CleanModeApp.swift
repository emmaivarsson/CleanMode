import SwiftUI

@main
struct CleanModeApp: App {
    @StateObject private var controller = CleanModeController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(controller)
        } label: {
            Image(systemName: controller.menuBarSymbolName)
                .symbolRenderingMode(.hierarchical)
                .accessibilityLabel(Text(controller.isLocked ? "Clean Mode on" : "Clean Mode"))
        }
        .menuBarExtraStyle(.menu)
    }
}
