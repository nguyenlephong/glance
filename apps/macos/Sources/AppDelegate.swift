import AppKit
import Carbon.HIToolbox
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var panelController: FloatingPanelController?
    private let translator: Translator = GoogleTranslator()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        AccessibilityHelper.requestPermissionIfNeeded()

        panelController = FloatingPanelController()
        panelController?.onSwapDirection = { [weak self] in
            self?.swapAndRetranslate()
        }
        panelController?.onReplaceRequested = { [weak self] in
            self?.replaceSelectedText()
        }

        menuBarController = MenuBarController(
            onTranslateClipboard: { [weak self] in self?.translateClipboard() },
            onShowSettings: { [weak self] in self?.showSettings() }
        )

        registerHotKeys()
    }

    // MARK: - Hotkeys

    private func registerHotKeys() {
        // ⌃⌥T — dịch text bôi đen
        HotKeyManager.shared.register(
            keyCode: UInt32(kVK_ANSI_T),
            modifiers: UInt32(controlKey | optionKey)
        ) { [weak self] in
            self?.handleTranslateHotKey()
        }

        // ⌃⌥⏎ — replace text bôi đen bằng bản dịch gần nhất
        HotKeyManager.shared.register(
            keyCode: UInt32(kVK_Return),
            modifiers: UInt32(controlKey | optionKey)
        ) { [weak self] in
            self?.replaceSelectedText()
        }
    }

    private func handleTranslateHotKey() {
        let mouse = NSEvent.mouseLocation
        Task { @MainActor in
            do {
                let text = try await TextCapture.captureSelectedText(
                    allowClipboardFallback: AppSettings.shared.allowClipboardFallback
                )
                translate(text: text, forceTarget: nil, forceSource: nil)
            } catch {
                panelController?.presentError(
                    error.localizedDescription,
                    at: mouse
                )
            }
        }
    }

    private func translateClipboard() {
        guard let text = NSPasteboard.general.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            NSSound.beep()
            return
        }
        translate(text: text, forceTarget: nil, forceSource: nil)
    }

    // MARK: - Translate flow

    private func swapAndRetranslate() {
        guard let previous = panelController?.lastTranslation else { return }
        let newTarget = previous.sourceLanguage
        let newSource = previous.targetLanguage
        translate(text: previous.translatedText, forceTarget: newTarget, forceSource: newSource)
    }

    private func translate(text: String, forceTarget: String?, forceSource: String?) {
        let mouseLocation = NSEvent.mouseLocation
        let settings = AppSettings.shared
        panelController?.showLoading(at: mouseLocation, originalText: text)

        Task { @MainActor in
            do {
                let firstTarget = forceTarget ?? settings.primaryLanguage
                let first = try await translator.translate(
                    text: text,
                    sourceLanguage: forceSource,
                    targetLanguage: firstTarget
                )

                if forceTarget == nil,
                   sameLanguage(first.sourceLanguage, firstTarget) {
                    let smartTarget = settings.preferredTarget(forDetectedSource: first.sourceLanguage)
                    if !sameLanguage(smartTarget, firstTarget) {
                        let second = try await translator.translate(
                            text: text,
                            sourceLanguage: first.sourceLanguage,
                            targetLanguage: smartTarget
                        )
                        panelController?.showResult(second, originalText: text)
                        return
                    }
                }
                panelController?.showResult(first, originalText: text)
            } catch {
                panelController?.showError(error.localizedDescription, originalText: text)
            }
        }
    }

    private func sameLanguage(_ a: String, _ b: String) -> Bool {
        let aBase = a.lowercased().split(separator: "-").first.map(String.init) ?? a
        let bBase = b.lowercased().split(separator: "-").first.map(String.init) ?? b
        return aBase == bBase
    }

    // MARK: - Replace selected text

    /// Thay đoạn đang bôi đen bằng bản dịch gần nhất.
    /// Cơ chế: snapshot clipboard → set bản dịch → ⌘V → restore clipboard.
    private func replaceSelectedText() {
        guard let last = panelController?.lastTranslation else {
            NSSound.beep()
            return
        }
        pasteText(last.translatedText)
    }

    private func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general

        let snapshot: [[NSPasteboard.PasteboardType: Data]] = pasteboard.pasteboardItems?.compactMap { item in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict.isEmpty ? nil : dict
        } ?? []

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Đóng panel để focus trả về app gốc, rồi ⌘V
        panelController?.dismissImmediately()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 70_000_000) // 70ms — chờ user nhả phím + focus
            Self.simulatePaste()
            try? await Task.sleep(nanoseconds: 250_000_000) // 250ms — chờ app gốc paste xong
            Self.restoreClipboard(snapshot: snapshot)
        }
    }

    private static func simulatePaste() {
        let source = CGEventSource(stateID: .privateState)
        let vKey = CGKeyCode(kVK_ANSI_V)
        let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)
    }

    private static func restoreClipboard(snapshot: [[NSPasteboard.PasteboardType: Data]]) {
        let pb = NSPasteboard.general
        pb.clearContents()
        guard !snapshot.isEmpty else { return }
        let items = snapshot.map { dict -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (type, data) in dict {
                item.setData(data, forType: type)
            }
            return item
        }
        pb.writeObjects(items)
    }

    private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}
