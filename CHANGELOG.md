# Changelog

Mọi thay đổi đáng chú ý của Glance sẽ được ghi ở đây.

Phiên bản theo [Semantic Versioning](https://semver.org/lang/vi/): `MAJOR.MINOR.PATCH`. Định dạng tham khảo [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/).

## [Unreleased]

### Đã thêm
- Skeleton sẵn sàng cho việc plug-in engine OpenAI / Anthropic (xem `Translator` protocol)

## [0.1.0] — 2026-05-21

Phiên bản công khai đầu tiên. Đủ chạy thực tế trên macOS 13+, đủ dùng hằng ngày cho việc dịch nhanh khi đọc tài liệu, chat, email.

### Đã thêm

- **Hotkey `⌃⌥T`** — global, hoạt động ở mọi app. Dịch text đang bôi đen và hiện kết quả ngay cạnh con trỏ
- **Hotkey `⌃⌥⏎`** — thay đoạn đang bôi đen bằng bản dịch gần nhất qua giả lập `⌘V` an toàn (snapshot + restore clipboard)
- **Floating panel** — `NSPanel` nonactivating, không steal focus khỏi app đang dùng. Có nút Swap (đảo chiều dịch), Replace, Copy, Close
- **Engine Google Translate** — free endpoint, không cần API key, không cần đăng ký
- **Auto-direction** — chọn ngôn ngữ chính (mặc định: Tiếng Việt) và phụ (Tiếng Anh) trong Settings. Glance tự nhận ngôn ngữ nguồn và dịch sang ngôn ngữ còn lại
- **Capture text bôi đen** — ưu tiên Accessibility API (`AXSelectedTextAttribute`), fallback an toàn qua clipboard cho app Electron (Zalo, Slack, VS Code, Chrome, Discord, Notion) — strict `changeCount` check, không bao giờ đọc clipboard cũ của user
- **Menu bar app** — `LSUIElement`, không Dock icon, < 1 MB binary
- **Settings** — chọn engine, cặp ngôn ngữ, timeout auto-dismiss (15s / 30s / 1 phút / 2 phút / 5 phút / không tự tắt), toggle clipboard fallback
- **Universal binary** — chạy native cả Apple Silicon (M1–M4) và Intel
- **Script đóng gói** — `apps/macos/scripts/release.sh` build `.dmg` + `.zip` trong `dist/`

### Hạn chế đã biết

- App ad-hoc sign — Gatekeeper sẽ chặn khi user khác download. Phải bypass bằng right-click → Open hoặc `xattr -dr com.apple.quarantine`. Xem `apps/macos/INSTALL.md`
- Chưa có OpenAI / Anthropic engine — đã thiết kế protocol nhưng chưa implement
- Chưa có OCR
- Chưa có lịch sử dịch
- Chưa cho custom hotkey
- Hotkey `⌃⌥T` có thể trùng với một số app (ví dụ Terminal). Quit app conflict hoặc đợi feature custom hotkey

[Unreleased]: https://github.com/nguyenlephong/glance/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/nguyenlephong/glance/releases/tag/v0.1.0
