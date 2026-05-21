# Glance (MVP)

> **Một cái liếc — hiểu mọi ngôn ngữ.**
> A glance is all it takes.

Dịch tức thì trên macOS bằng phím tắt `⌃⌥T` — không rời app hiện tại. Phiên bản MVP này tập trung vào:

- Menu bar app (không Dock icon — `LSUIElement = YES`)
- Global hotkey `⌃⌥T` (Carbon `RegisterEventHotKey`)
- Capture văn bản đang được bôi đen qua Accessibility API, fallback bằng giả lập `⌘C`
- Floating panel SwiftUI (`NSPanel` nonactivating) hiện kết quả ngay cạnh con trỏ
- Engine dịch: **Google Translate** (miễn phí, không cần API key)
- Settings: chọn ngôn ngữ đích, lưu vào `UserDefaults`

> OpenAI / Anthropic / OCR / History / Streaming sẽ ở phiên bản sau (xem `task.md`).

## Yêu cầu

- macOS 13+ (Ventura trở lên)
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) để generate `.xcodeproj` từ `project.yml`

```bash
brew install xcodegen
```

## Build & Run

```bash
cd Glance
xcodegen generate
open Glance.xcodeproj
```

Trong Xcode: chọn scheme `Glance` → bấm ▶ (Cmd+R).

Hoặc build từ command line:

```bash
xcodebuild -project Glance.xcodeproj -scheme Glance -configuration Debug build
```

Binary sẽ nằm ở `~/Library/Developer/Xcode/DerivedData/Glance-*/Build/Products/Debug/Glance.app`. Mở bằng `open path/to/Glance.app`.

## Cấp quyền (lần đầu chạy)

App sẽ tự bật prompt **Accessibility** — vào `System Settings → Privacy & Security → Accessibility` và bật `Glance`. Đây là quyền bắt buộc để:

1. Đọc văn bản đang bôi đen từ app khác (qua `AXSelectedTextAttribute`)
2. Giả lập `⌘C` cho fallback clipboard

Không cần Screen Recording (chỉ cần khi thêm OCR ở phiên bản sau).

## Sử dụng

1. Bôi đen / highlight bất kỳ văn bản nào trong Safari, Chrome, Slack, PDF, Mail...
2. Bấm **`⌃⌥T`** (Control + Option + T)
3. Panel dịch xuất hiện cạnh con trỏ → đọc kết quả → bấm `Esc` hoặc click ra ngoài để đóng

Click icon Glance trên menu bar để mở Settings hoặc dịch nhanh nội dung trong clipboard.

## Cấu trúc thư mục

```
Glance/
├── project.yml                 # XcodeGen config
├── Glance.entitlements
├── Resources/
│   └── (Info.plist sinh tự động bởi XcodeGen)
└── Sources/
    ├── GlanceApp.swift                 # @main entry
    ├── AppDelegate.swift               # Orchestrator (@MainActor)
    ├── HotKeyManager.swift             # Carbon RegisterEventHotKey
    ├── AccessibilityHelper.swift       # AX permission prompt
    ├── TextCapture.swift               # AXSelectedText + clipboard fallback
    ├── FloatingPanel.swift             # NSPanel nonactivating
    ├── FloatingPanelController.swift   # Show / dismiss / position
    ├── TranslationView.swift           # SwiftUI panel UI
    ├── Translator.swift                # Protocol + types
    ├── GoogleTranslator.swift          # Google free endpoint
    ├── Settings.swift                  # AppSettings (UserDefaults)
    ├── SettingsView.swift              # SwiftUI settings UI
    └── MenuBarController.swift         # NSStatusItem menu
```

## Lộ trình kế tiếp

- [ ] OpenAI / Anthropic engine + Keychain lưu API key
- [ ] Streaming SSE cho AI response
- [ ] OCR qua Vision (`VNRecognizeTextRequest`)
- [ ] Lịch sử dịch (SQLite trên `~/Library/Application Support/Glance`)
- [ ] Custom hotkey trong Settings
- [ ] Context-aware prompt cho AI
- [ ] Sparkle auto-update + notarization

## Troubleshooting

- **Bấm `⌃⌥T` không hiện gì**: Kiểm tra `System Settings → Privacy & Security → Accessibility` → Glance đã bật chưa. Nếu vẫn không được, quit app và mở lại.
- **Panel hiện "Không có kết quả dịch"**: Văn bản chưa được copy được. Hãy đảm bảo đã bôi đen rõ ràng trước khi bấm hotkey.
- **Hotkey conflict**: `⌃⌥T` có thể trùng với app khác (ví dụ Terminal). Phiên bản sau sẽ cho phép tự đổi hotkey.
