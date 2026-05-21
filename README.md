<div align="center">

# Glance

**Một cái liếc — hiểu mọi ngôn ngữ.**
*A glance is all it takes.*

Dịch tức thì trên màn hình bằng một phím tắt. Bôi đen → `⌃⌥T` → đọc bản dịch ngay cạnh con trỏ. Không bao giờ rời app đang dùng.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: macOS 13+](https://img.shields.io/badge/Platform-macOS%2013%2B-blue.svg)](apps/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[Cài đặt](#-cài-đặt) · [Tính năng](#-tính-năng) · [Contributing](CONTRIBUTING.md) · [Tech spec](apps/macos/docs/TECH_SPEC.md) · [Roadmap](docs/ROADMAP.md)

</div>

---

## ✨ Tính năng

- **Phím tắt global `⌃⌥T`** — dịch text đang bôi đen ở app bất kỳ (Safari, Mail, Zalo, Slack, VS Code, Chrome…)
- **Floating panel** — kết quả hiện ngay cạnh con trỏ, không steal focus, không che app đang dùng
- **Replace bằng `⌃⌥⏎`** — thay text gốc bằng bản dịch chỉ với 1 hotkey
- **Auto-direction** — text tiếng Anh → dịch sang Việt, text Việt → dịch sang Anh (cấu hình cặp ngôn ngữ trong Settings)
- **Engine miễn phí** — Google Translate, không cần API key, không cần đăng ký
- **Hỗ trợ app Electron** — clipboard fallback an toàn cho Zalo, Slack, VS Code, Discord, Notion, Chrome (snapshot + restore clipboard, chỉ đọc text vừa copy)
- **Tự đóng panel** — chỉnh được 15s / 30s / 1 phút / 2 phút / 5 phút / Không tự tắt
- **Menu bar app** — không Dock icon, < 1 MB binary

## 📦 Cài đặt

### Apple Silicon & Intel Mac (macOS 13+)

Tải `.dmg` mới nhất từ [Releases](https://github.com/nguyenlephong/glance/releases) (hoặc build từ source — xem [Development](#-development) bên dưới).

→ Xem [`apps/macos/INSTALL.md`](apps/macos/INSTALL.md) để biết cách **bypass Gatekeeper** lần đầu (vì app chưa notarize qua Apple Developer Program).

### Build từ source

```bash
git clone git@github.com:nguyenlephong/glance.git
cd glance/apps/macos
brew install xcodegen
xcodegen generate
open Glance.xcodeproj    # Cmd+R trong Xcode
```

## 🎬 Cách dùng

| Hotkey | Hành động |
|---|---|
| `⌃⌥T` | Dịch text đang bôi đen |
| `⌃⌥⏎` | Thay text bôi đen bằng bản dịch gần nhất |
| `Esc` | Đóng panel |

## 🗺️ Roadmap & Multi-platform

Hiện chỉ có macOS. Kế hoạch mở rộng:

- [x] **macOS** — Swift / SwiftUI native
- [ ] **Windows** — hướng cân nhắc: C#/WPF, Tauri, hoặc Electron
- [ ] **Linux** — hướng cân nhắc: Tauri
- [ ] OpenAI / Anthropic engine (BYO API key)
- [ ] OCR qua Apple Vision (chụp vùng + dịch)
- [ ] Lịch sử dịch local (SQLite)
- [ ] Streaming SSE cho AI response
- [ ] Sparkle auto-update

Chi tiết xem [`docs/ROADMAP.md`](docs/ROADMAP.md).

## 🏗️ Cấu trúc repo

```
glance/
├── apps/
│   └── macos/              # Swift/SwiftUI macOS app (hiện có)
│       ├── Sources/        # Swift source files
│       ├── Resources/      # Info.plist (XcodeGen sinh)
│       ├── docs/           # Tech spec, sơ đồ PlantUML
│       ├── scripts/        # release.sh — build .dmg
│       ├── project.yml     # XcodeGen config
│       ├── INSTALL.md      # Hướng dẫn cài cho end user
│       └── README.md       # Dev quick start cho platform này
├── docs/                   # Cross-platform docs
│   ├── ARCHITECTURE.md     # Kiến trúc tổng + chia sẻ code giữa platform
│   ├── ROADMAP.md          # Features & platforms timeline
│   └── PRODUCT_SPEC.md     # Spec gốc của sản phẩm
├── assets/                 # Screenshots, demo GIF (sẽ thêm sau)
├── .github/                # Issue/PR templates, CI workflows
├── README.md               # File anh đang đọc
├── CONTRIBUTING.md         # Hướng dẫn cho contributor
├── CODE_OF_CONDUCT.md      # Contributor Covenant
├── CHANGELOG.md            # Lịch sử thay đổi (Keep a Changelog)
└── LICENSE                 # MIT
```

## 🛠️ Development

```bash
# Lần đầu setup
brew install xcodegen

# Generate Xcode project + chạy
cd apps/macos
xcodegen generate
open Glance.xcodeproj

# Build .dmg cho release
./scripts/release.sh        # output: dist/Glance-X.Y.Z.dmg + .zip
```

Đọc thêm:
- [Tech spec & sơ đồ PlantUML](apps/macos/docs/TECH_SPEC.md)
- [Contribution guide](CONTRIBUTING.md)

## 🔐 Privacy

- Văn bản dịch **chỉ** gửi đến endpoint translation engine anh chọn (mặc định Google Translate). Không có backend của Glance.
- Glance **không bao giờ đọc clipboard cũ** của anh. Chi tiết cơ chế ở [ADR-2 trong Tech Spec](apps/macos/docs/TECH_SPEC.md#7-quyết-định-thiết-kế-adr-style).
- Settings + cặp ngôn ngữ lưu local trong `UserDefaults`.
- Lịch sử dịch (khi có) sẽ lưu local SQLite, không sync.

## 🤝 Contributing

PR + issue welcome! Đọc [CONTRIBUTING.md](CONTRIBUTING.md) trước khi bắt đầu.

Mọi người tham gia đồng ý tuân theo [Code of Conduct](CODE_OF_CONDUCT.md).

## 📄 License

[MIT](LICENSE) © 2026 Phong Nguyen

---

<div align="center">

Made with ☕ in Vietnam · [Báo lỗi](https://github.com/nguyenlephong/glance/issues/new/choose)

</div>
