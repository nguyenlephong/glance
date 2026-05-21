import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController {
    private var panel: FloatingPanel?
    private let viewModel = TranslationViewModel()
    private var dismissMonitor: Any?
    private var autoDismissTask: DispatchWorkItem?

    /// Callback khi user bấm nút đảo chiều ⇄ trong panel.
    var onSwapDirection: (() -> Void)?

    /// Callback khi user bấm Replace.
    var onReplaceRequested: (() -> Void)?

    /// Kết quả dịch gần nhất — để AppDelegate dùng cho thao tác đảo chiều.
    var lastTranslation: TranslationResult? {
        if case .success(let result) = viewModel.state { return result }
        return nil
    }

    func showLoading(at point: NSPoint, originalText: String) {
        viewModel.originalText = originalText
        viewModel.state = .loading
        present(at: point)
    }

    func showResult(_ result: TranslationResult, originalText: String) {
        viewModel.originalText = originalText
        viewModel.state = .success(result)
        scheduleAutoDismissUsingSettings()
    }

    func showError(_ message: String, originalText: String) {
        viewModel.originalText = originalText
        viewModel.state = .failure(message)
        scheduleAutoDismissUsingSettings(maxOverride: 15)
    }

    /// Present panel với một thông báo lỗi ngay tại vị trí chuột — dùng khi
    /// chưa từng có translation nào (vd: không bôi đen được, chưa có quyền AX).
    func presentError(_ message: String, at point: NSPoint) {
        viewModel.originalText = ""
        viewModel.state = .failure(message)
        present(at: point)
        scheduleAutoDismissUsingSettings(maxOverride: 15)
    }

    /// Đọc setting `autoDismissSeconds`. 0 = không tự tắt.
    /// `maxOverride` để cap timeout cho error state (không cần giữ lâu như success).
    private func scheduleAutoDismissUsingSettings(maxOverride: Int? = nil) {
        var seconds = AppSettings.shared.autoDismissSeconds
        if seconds == 0 {
            autoDismissTask?.cancel()
            autoDismissTask = nil
            return
        }
        if let cap = maxOverride { seconds = min(seconds, cap) }
        scheduleAutoDismiss(after: TimeInterval(seconds))
    }

    private func present(at point: NSPoint) {
        autoDismissTask?.cancel()

        let panel = panel ?? makePanel()
        self.panel = panel

        let frame = NSRect(x: point.x + 12, y: point.y - 80, width: 360, height: 180)
        let adjusted = clampToScreen(frame)
        panel.setFrame(adjusted, display: false)

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 1
        }

        installDismissMonitor()
    }

    private func makePanel() -> FloatingPanel {
        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 180))
        let host = NSHostingView(rootView: TranslationView(
            viewModel: viewModel,
            onDismiss: { [weak self] in self?.dismiss() },
            onSwap: { [weak self] in self?.onSwapDirection?() },
            onReplace: { [weak self] in self?.onReplaceRequested?() }
        ))
        host.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView(frame: .zero)
        container.addSubview(host)
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: container.topAnchor),
            host.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            host.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        panel.contentView = container
        return panel
    }

    private func installDismissMonitor() {
        removeDismissMonitor()
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            if event.type == .keyDown && event.keyCode != 53 { return }
            DispatchQueue.main.async { self?.dismiss() }
        }
    }

    private func removeDismissMonitor() {
        if let dismissMonitor {
            NSEvent.removeMonitor(dismissMonitor)
            self.dismissMonitor = nil
        }
    }

    private func scheduleAutoDismiss(after seconds: TimeInterval) {
        autoDismissTask?.cancel()
        let task = DispatchWorkItem { [weak self] in self?.dismiss() }
        autoDismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: task)
    }

    private func dismiss() {
        removeDismissMonitor()
        autoDismissTask?.cancel()
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    /// Ẩn panel ngay không animation — dùng khi cần focus trả về app gốc gấp (replace flow).
    func dismissImmediately() {
        removeDismissMonitor()
        autoDismissTask?.cancel()
        panel?.alphaValue = 0
        panel?.orderOut(nil)
    }

    private func clampToScreen(_ frame: NSRect) -> NSRect {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(frame.origin) }) ?? NSScreen.main else {
            return frame
        }
        var f = frame
        let visible = screen.visibleFrame
        if f.maxX > visible.maxX { f.origin.x = visible.maxX - f.width - 8 }
        if f.minX < visible.minX { f.origin.x = visible.minX + 8 }
        if f.minY < visible.minY { f.origin.y = visible.minY + 8 }
        if f.maxY > visible.maxY { f.origin.y = visible.maxY - f.height - 8 }
        return f
    }
}
