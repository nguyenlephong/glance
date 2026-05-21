import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Keys {
        static let engine = "glance.engine"
        static let primaryLanguage = "glance.primaryLanguage"
        static let secondaryLanguage = "glance.secondaryLanguage"
        static let saveHistory = "glance.saveHistory"
        static let uiLanguage = "glance.uiLanguage"
        static let allowClipboardFallback = "glance.allowClipboardFallback"
        static let autoDismissSeconds = "glance.autoDismissSeconds"
    }

    @Published var engine: TranslationEngine {
        didSet { UserDefaults.standard.set(engine.rawValue, forKey: Keys.engine) }
    }

    /// Ngôn ngữ chính của người dùng (mặc định: tiếng Việt).
    /// Mọi văn bản KHÔNG phải tiếng này sẽ được dịch sang đây.
    @Published var primaryLanguage: String {
        didSet { UserDefaults.standard.set(primaryLanguage, forKey: Keys.primaryLanguage) }
    }

    /// Ngôn ngữ phụ — khi văn bản đã ở ngôn ngữ chính, sẽ dịch sang đây.
    @Published var secondaryLanguage: String {
        didSet { UserDefaults.standard.set(secondaryLanguage, forKey: Keys.secondaryLanguage) }
    }

    @Published var saveHistory: Bool {
        didSet { UserDefaults.standard.set(saveHistory, forKey: Keys.saveHistory) }
    }

    @Published var uiLanguage: String {
        didSet { UserDefaults.standard.set(uiLanguage, forKey: Keys.uiLanguage) }
    }

    /// Cho phép giả lập `⌘C` để lấy text bôi đen ở app không phơi bày Accessibility
    /// (Chrome, VS Code, Zalo, Slack, Discord, Notion…). An toàn vì:
    /// - Clipboard cũ được restore ngay sau khi đọc
    /// - CHỈ đọc nếu thực sự có copy mới (changeCount thay đổi)
    @Published var allowClipboardFallback: Bool {
        didSet { UserDefaults.standard.set(allowClipboardFallback, forKey: Keys.allowClipboardFallback) }
    }

    /// Thời gian tự đóng panel sau khi hiện kết quả (giây).
    /// 0 = không tự đóng. Mặc định 60s.
    @Published var autoDismissSeconds: Int {
        didSet { UserDefaults.standard.set(autoDismissSeconds, forKey: Keys.autoDismissSeconds) }
    }

    private init() {
        let defaults = UserDefaults.standard
        let raw = defaults.string(forKey: Keys.engine) ?? TranslationEngine.google.rawValue
        self.engine = TranslationEngine(rawValue: raw) ?? .google
        self.primaryLanguage = defaults.string(forKey: Keys.primaryLanguage)
            ?? defaults.string(forKey: "glance.targetLanguage") // legacy migration
            ?? "vi"
        self.secondaryLanguage = defaults.string(forKey: Keys.secondaryLanguage) ?? "en"
        self.saveHistory = defaults.object(forKey: Keys.saveHistory) as? Bool ?? false
        self.uiLanguage = defaults.string(forKey: Keys.uiLanguage) ?? "vi"
        self.allowClipboardFallback = defaults.object(forKey: Keys.allowClipboardFallback) as? Bool ?? true
        self.autoDismissSeconds = defaults.object(forKey: Keys.autoDismissSeconds) as? Int ?? 60
    }

    /// Quyết định ngôn ngữ đích dựa trên ngôn ngữ nguồn được detect.
    /// Nếu nguồn = chính → dịch sang phụ; ngược lại → dịch sang chính.
    func preferredTarget(forDetectedSource source: String?) -> String {
        guard let source = source?.lowercased() else { return primaryLanguage }
        if matches(source, primaryLanguage) { return secondaryLanguage }
        return primaryLanguage
    }

    private func matches(_ a: String, _ b: String) -> Bool {
        let aBase = a.split(separator: "-").first.map(String.init) ?? a
        let bBase = b.lowercased().split(separator: "-").first.map(String.init) ?? b
        return aBase == bBase
    }
}

struct AutoDismissOption: Identifiable, Hashable {
    let seconds: Int
    let label: String
    var id: Int { seconds }

    static let presets: [AutoDismissOption] = [
        .init(seconds: 15, label: "15 giây"),
        .init(seconds: 30, label: "30 giây"),
        .init(seconds: 60, label: "1 phút"),
        .init(seconds: 120, label: "2 phút"),
        .init(seconds: 300, label: "5 phút"),
        .init(seconds: 0, label: "Không tự tắt")
    ]
}

struct LanguageOption: Identifiable, Hashable {
    let code: String
    let nameVi: String
    let nameEn: String
    var id: String { code }
}

enum SupportedLanguages {
    static let all: [LanguageOption] = [
        .init(code: "vi", nameVi: "Tiếng Việt", nameEn: "Vietnamese"),
        .init(code: "en", nameVi: "Tiếng Anh", nameEn: "English"),
        .init(code: "ja", nameVi: "Tiếng Nhật", nameEn: "Japanese"),
        .init(code: "ko", nameVi: "Tiếng Hàn", nameEn: "Korean"),
        .init(code: "zh-CN", nameVi: "Tiếng Trung (Giản thể)", nameEn: "Chinese (Simplified)"),
        .init(code: "fr", nameVi: "Tiếng Pháp", nameEn: "French"),
        .init(code: "de", nameVi: "Tiếng Đức", nameEn: "German"),
        .init(code: "es", nameVi: "Tiếng Tây Ban Nha", nameEn: "Spanish"),
        .init(code: "ru", nameVi: "Tiếng Nga", nameEn: "Russian"),
        .init(code: "th", nameVi: "Tiếng Thái", nameEn: "Thai")
    ]

    static func name(for code: String) -> String {
        let base = code.split(separator: "-").first.map(String.init) ?? code
        return all.first { $0.code == code || $0.code.hasPrefix(base) }?.nameVi
            ?? code.uppercased()
    }
}
