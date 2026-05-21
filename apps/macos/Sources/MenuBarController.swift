import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onTranslateClipboard: () -> Void
    private let onShowSettings: () -> Void

    init(onTranslateClipboard: @escaping () -> Void,
         onShowSettings: @escaping () -> Void) {
        self.onTranslateClipboard = onTranslateClipboard
        self.onShowSettings = onShowSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            let image = NSImage(
                systemSymbolName: "character.bubble.fill",
                accessibilityDescription: "Glance"
            )
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Glance — ⌃⌥T để dịch"
        }

        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let hotkeyHint = NSMenuItem(
            title: "Bôi đen văn bản và bấm ⌃⌥T",
            action: nil,
            keyEquivalent: ""
        )
        hotkeyHint.isEnabled = false
        menu.addItem(hotkeyHint)

        menu.addItem(.separator())

        let clipboardItem = NSMenuItem(
            title: "Dịch nội dung clipboard (thủ công)",
            action: #selector(translateClipboard),
            keyEquivalent: ""
        )
        clipboardItem.target = self
        menu.addItem(clipboardItem)

        let settingsItem = NSMenuItem(
            title: "Cài đặt…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Thoát Glance",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func translateClipboard() {
        onTranslateClipboard()
    }

    @objc private func openSettings() {
        onShowSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
