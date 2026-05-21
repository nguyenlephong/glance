# Contributing to Glance

Cảm ơn anh/chị đã quan tâm đóng góp cho Glance ❤️ Tài liệu này hướng dẫn cách tham gia hiệu quả.

> Mọi người tham gia repo này đồng ý tuân theo [Code of Conduct](CODE_OF_CONDUCT.md).

## Bằng cách nào tôi có thể giúp?

- 🐛 **Báo bug** — mở [issue mới](https://github.com/nguyenlephong/glance/issues/new/choose) với template Bug report
- 💡 **Đề xuất tính năng** — mở issue với template Feature request
- 📖 **Cải thiện docs** — typo, ví dụ rõ hơn, dịch sang tiếng Anh
- 🛠️ **Code** — pick một issue gắn nhãn `good first issue` hoặc `help wanted`
- 🌐 **Đóng gói cho platform mới** — Windows / Linux (đọc [Roadmap](docs/ROADMAP.md))

## Trước khi mở PR

1. **Tìm issue tương ứng** — hoặc mở issue mới để thảo luận thiết kế trước khi code (đặc biệt với change lớn)
2. **Đảm bảo build pass** — `cd apps/macos && xcodegen generate && xcodebuild build`
3. **Tuân theo style** — mã Swift theo [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
4. **Commit nhỏ, tập trung** — một commit = một thay đổi logic, message rõ ràng

## Quy trình development (macOS)

### Setup

```bash
git clone git@github.com:nguyenlephong/glance.git
cd glance/apps/macos
brew install xcodegen
xcodegen generate
open Glance.xcodeproj
```

### Build .dmg để test phân phối

```bash
cd apps/macos
./scripts/release.sh
# output: dist/Glance-X.Y.Z.dmg
```

### Cấu trúc code

Đọc [`apps/macos/docs/TECH_SPEC.md`](apps/macos/docs/TECH_SPEC.md) — có sơ đồ PlantUML cho từng flow chính.

Layer chính:

| Layer | File | Trách nhiệm |
|---|---|---|
| Hotkey | `HotKeyManager.swift` | Carbon `RegisterEventHotKey` global hotkeys |
| Capture | `TextCapture.swift`, `AccessibilityHelper.swift` | Đọc text bôi đen qua AX + clipboard fallback |
| Translation | `Translator.swift`, `GoogleTranslator.swift` | Protocol + Google engine |
| UI | `FloatingPanel.swift`, `FloatingPanelController.swift`, `TranslationView.swift` | NSPanel nonactivating + SwiftUI |
| Settings | `Settings.swift`, `SettingsView.swift` | UserDefaults wrapper + SwiftUI form |
| Menu bar | `MenuBarController.swift` | NSStatusItem |

## Coding conventions

### Swift

- **Indent**: 4 spaces, không tab
- **Naming**: PascalCase cho type, camelCase cho biến/hàm
- **Immutability**: prefer `let` over `var`
- **MainActor**: UI code và `AppSettings` đã `@MainActor` — giữ nguyên
- **No force unwrap** ngoại trừ trường hợp constraint chắc chắn (ví dụ `URLComponents(string: literal)!`)
- **Comment tiếng Việt OK** cho doc string nội bộ; public API dùng tiếng Anh

### Commit message

Theo [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: thêm OpenAI translator
fix: clipboard không restore khi Replace fail
docs: cập nhật INSTALL.md cho macOS 14
refactor: tách FloatingPanelController thành 2 file
chore: bump version 0.1.0 → 0.2.0
```

## Quy trình PR

1. **Fork** repo, tạo branch từ `main`: `git checkout -b feat/openai-engine`
2. Code + test thủ công (bôi đen text ở Safari, Mail, Zalo, Chrome)
3. **Build pass**: `xcodegen generate && xcodebuild build`
4. Push lên fork, mở PR vào `main`
5. PR description rõ:
   - **Why** — vấn đề đang giải quyết
   - **What** — thay đổi gì
   - **How tested** — đã test thế nào (app nào, scenario nào)
   - Screenshot / GIF nếu thay đổi UI
6. Reviewer comment → fix → push tiếp lên cùng branch
7. Squash & merge khi approve

## Đóng gói platform mới (Windows / Linux)

Glance hiện chỉ có macOS. Nếu anh/chị muốn port:

1. Mở issue thảo luận stack (C#/WPF, Tauri, Electron, Flutter…)
2. Tạo folder `apps/<platform>/` song song với `apps/macos/`
3. Implement đủ 4 thứ tối thiểu:
   - Global hotkey
   - Capture selected text (AX equivalent + clipboard fallback)
   - Floating window không steal focus
   - Translation engine (re-use endpoint Google free)
4. Update [`docs/ROADMAP.md`](docs/ROADMAP.md) check ☑ platform mới
5. Update README.md badge & install section

## Có câu hỏi?

Mở issue mới với template **Question** hoặc liên hệ qua [email maintainer](mailto:phongnguyen.itengineer@gmail.com).
