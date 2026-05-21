import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("Tổng quan", systemImage: "gearshape") }
            translationTab
                .tabItem { Label("Dịch", systemImage: "globe") }
            aboutTab
                .tabItem { Label("Về Glance", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 320)
    }

    private var generalTab: some View {
        Form {
            Section {
                HStack {
                    Text("Phím tắt dịch nhanh")
                    Spacer()
                    Text("⌃ ⌥ T")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                        )
                }
                Toggle("Lưu lịch sử dịch trên máy", isOn: $settings.saveHistory)
            }
            Section("Floating panel") {
                Picker("Tự đóng sau", selection: $settings.autoDismissSeconds) {
                    ForEach(AutoDismissOption.presets) { opt in
                        Text(opt.label).tag(opt.seconds)
                    }
                }
                Text("Panel sẽ tự ẩn sau khoảng thời gian này. Click ra ngoài hoặc bấm Esc cũng đóng ngay.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Đọc văn bản bôi đen") {
                Toggle("Hỗ trợ app Electron (Zalo, Slack, VS Code, Chrome…)", isOn: $settings.allowClipboardFallback)
                Text("Khi bật, nếu Accessibility API không đọc được text, Glance sẽ giả lập ⌘C để lấy đoạn anh đã bôi đen. Clipboard hiện tại của anh được khôi phục ngay sau đó và Glance KHÔNG bao giờ đọc nội dung clipboard cũ.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Ngôn ngữ giao diện") {
                Picker("Ngôn ngữ", selection: $settings.uiLanguage) {
                    Text("Tiếng Việt").tag("vi")
                    Text("English").tag("en")
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(20)
    }

    private var translationTab: some View {
        Form {
            Section("Engine dịch") {
                Picker("Engine", selection: $settings.engine) {
                    ForEach(TranslationEngine.allCases) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
                .pickerStyle(.segmented)

                if settings.engine != .google {
                    Text("Bản MVP hiện chỉ hỗ trợ Google Translate. OpenAI và Anthropic sẽ được bật ở phiên bản kế tiếp.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Cặp ngôn ngữ") {
                Picker("Ngôn ngữ chính", selection: $settings.primaryLanguage) {
                    ForEach(SupportedLanguages.all) { lang in
                        Text(lang.nameVi).tag(lang.code)
                    }
                }
                Picker("Ngôn ngữ phụ", selection: $settings.secondaryLanguage) {
                    ForEach(SupportedLanguages.all) { lang in
                        Text(lang.nameVi).tag(lang.code)
                    }
                }
                Text("Glance tự nhận ngôn ngữ của văn bản: nếu là *chính* sẽ dịch sang *phụ*, và ngược lại. Bấm nút ⇄ trong panel để đảo chiều thủ công.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "character.bubble.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text("Glance")
                .font(.title2.weight(.semibold))
            Text("Một cái liếc — hiểu mọi ngôn ngữ.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Phiên bản 0.1.0 (MVP)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
