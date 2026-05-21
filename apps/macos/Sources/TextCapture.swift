import AppKit
import ApplicationServices
import Carbon.HIToolbox

enum TextCaptureError: LocalizedError {
    case accessibilityNotGranted
    case noSelection

    var errorDescription: String? {
        switch self {
        case .accessibilityNotGranted:
            return "Glance chưa được cấp quyền Accessibility. Mở System Settings → Privacy & Security → Accessibility và bật Glance."
        case .noSelection:
            return "Không đọc được văn bản đang bôi đen. Hãy chắc chắn anh đã highlight text trước khi bấm ⌃⌥T."
        }
    }
}

enum TextCapture {
    /// Đọc văn bản đang được bôi đen.
    ///
    /// Chiến lược:
    /// 1. Thử Accessibility API (`AXSelectedTextAttribute`) — instant, không động vào clipboard.
    /// 2. Nếu AX trả về nil VÀ user cho phép → fallback an toàn qua clipboard:
    ///    - Snapshot clipboard hiện tại + `changeCount`
    ///    - Giả lập `⌘C` (dùng `.privateState` để không bị ảnh hưởng ⌃⌥ đang giữ)
    ///    - Poll `changeCount`. CHỈ đọc text nếu count tăng (= có copy mới).
    ///      Nếu count KHÔNG đổi → user chưa bôi đen gì → trả nil, KHÔNG đọc clipboard cũ.
    ///    - Restore clipboard cũ.
    static func captureSelectedText(allowClipboardFallback: Bool) async throws -> String {
        guard AccessibilityHelper.isTrusted() else {
            throw TextCaptureError.accessibilityNotGranted
        }

        if let text = selectedTextFromAccessibility() {
            return text
        }

        guard allowClipboardFallback else {
            throw TextCaptureError.noSelection
        }

        if let text = await selectedTextFromClipboardSafely() {
            return text
        }
        throw TextCaptureError.noSelection
    }

    // MARK: - Accessibility

    private static func selectedTextFromAccessibility() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        )
        guard focusResult == .success, let focusedRef else { return nil }
        let focused = focusedRef as! AXUIElement

        var selectedRef: CFTypeRef?
        let selResult = AXUIElementCopyAttributeValue(
            focused,
            kAXSelectedTextAttribute as CFString,
            &selectedRef
        )
        guard selResult == .success,
              let text = selectedRef as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return text
    }

    // MARK: - Clipboard fallback (safe)

    /// Bao giờ cũng restore clipboard. KHÔNG bao giờ đọc nội dung clipboard cũ.
    private static func selectedTextFromClipboardSafely() async -> String? {
        let pasteboard = NSPasteboard.general

        // Snapshot toàn bộ items + types
        let snapshot: [[NSPasteboard.PasteboardType: Data]] = pasteboard.pasteboardItems?.compactMap { item in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type] = data
                }
            }
            return dict.isEmpty ? nil : dict
        } ?? []

        let originalChangeCount = pasteboard.changeCount

        // Cho user kịp nhả ⌃⌥ trước khi mình post ⌘C
        try? await Task.sleep(nanoseconds: 60_000_000) // 60ms

        simulateCopy()

        // Poll changeCount tối đa 400ms
        var copiedText: String?
        let deadline = Date().addingTimeInterval(0.4)
        while Date() < deadline {
            if pasteboard.changeCount != originalChangeCount {
                copiedText = pasteboard.string(forType: .string)
                break
            }
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        }

        // Restore clipboard cũ — dù copy có thành công hay không
        restoreClipboard(snapshot: snapshot)

        // CHỈ trả về nếu thực sự đã có copy mới (changeCount đã đổi)
        guard let text = copiedText,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return text
    }

    private static func restoreClipboard(snapshot: [[NSPasteboard.PasteboardType: Data]]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard !snapshot.isEmpty else { return }
        let items: [NSPasteboardItem] = snapshot.map { dict in
            let item = NSPasteboardItem()
            for (type, data) in dict {
                item.setData(data, forType: type)
            }
            return item
        }
        pasteboard.writeObjects(items)
    }

    private static func simulateCopy() {
        // .privateState ⇒ OS bỏ qua trạng thái ⌃⌥ thực mà user đang giữ.
        let source = CGEventSource(stateID: .privateState)
        let cKey = CGKeyCode(kVK_ANSI_C)

        let down = CGEvent(keyboardEventSource: source, virtualKey: cKey, keyDown: true)
        down?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)

        let up = CGEvent(keyboardEventSource: source, virtualKey: cKey, keyDown: false)
        up?.flags = .maskCommand
        up?.post(tap: .cghidEventTap)
    }
}
