# Roadmap

> Roadmap này phản ánh **ý định** của maintainer ở thời điểm cập nhật. Không phải cam kết. Thứ tự có thể đổi theo phản hồi user thực tế và thời gian rảnh.
>
> Cập nhật lần cuối: 2026-05-21

## Hiện tại — v0.1.0

✅ macOS MVP đã chạy hằng ngày. Đủ dùng cho việc đọc tài liệu, chat đa ngôn ngữ.

Xem [CHANGELOG.md](../CHANGELOG.md) để biết chi tiết.

---

## Tiếp theo — v0.2.x (đang định hình)

Mục tiêu phiên bản kế: làm cho Glance "đủ dùng cho người không phải dev". Hai hướng song song:

### Quality of life

- [ ] **Custom hotkey trong Settings** — thay vì hard-code `⌃⌥T`. Cho phép user record hotkey mới
- [ ] **Original text trong panel** — hiện cả text gốc bên cạnh bản dịch (toggle)
- [ ] **Onboarding** — màn hình lần đầu chạy hướng dẫn 3 bước: cấp quyền AX → thử bôi đen text → bấm hotkey
- [ ] **Indicator AX permission** trong menu bar (icon đổi màu khi chưa cấp quyền)
- [ ] **Lịch sử dịch** local SQLite, có search + copy + delete entry

### AI engine

- [ ] **OpenAI engine** — user nhập API key, lưu Keychain
- [ ] **Anthropic engine** — tương tự
- [ ] **Streaming SSE** — bản dịch hiện dần khi AI đang trả
- [ ] **Context input** — field nhỏ trong panel cho phép gõ ngữ cảnh ("legal", "technical", "casual")

---

## Trung hạn — v0.3.x → v1.0

### Distribution

- [ ] **Sparkle auto-update** — user không phải tự tải bản mới
- [ ] **Apple Developer ID + notarization** — bỏ bước "right-click → Open" lần đầu. Cần $99/năm
- [ ] **Homebrew Cask** — `brew install --cask glance`
- [ ] **Landing page** — thay vì README làm marketing material

### Tính năng

- [ ] **OCR qua Apple Vision** — hotkey thứ 3 (`⌃⌥O`), chụp vùng màn hình, OCR, dịch. On-device, không network cho bước OCR
- [ ] **Speak button** — đọc bản dịch qua `AVSpeechSynthesizer`
- [ ] **Glossary cá nhân** — danh sách từ user muốn dịch theo cách riêng (ví dụ tên riêng giữ nguyên)
- [ ] **Translate input** — dialog box riêng để gõ text trực tiếp, không cần bôi đen từ app khác

---

## Dài hạn — sau v1.0

### Multi-platform

- [ ] **Windows** — đọc [ARCHITECTURE.md](ARCHITECTURE.md) phần "Windows gợi ý". Hướng cân nhắc: C#/WinUI 3 hoặc Tauri. Cần một contributor đứng ra port — maintainer hiện tại không có máy Windows
- [ ] **Linux** — phức tạp hơn vì Wayland vs X11. Có thể là Tauri

### Mở rộng engine

- [ ] **DeepL** — chất lượng dịch nhiều cặp ngôn ngữ tốt hơn Google
- [ ] **Local LLM** (Ollama / llama.cpp) — không cần internet, hoàn toàn on-device
- [ ] **Apple Foundation Models** — trên macOS 15.1+ có Foundation Models API, có thể dùng on-device

---

## Đã quyết định KHÔNG làm (out of scope)

Để giữ Glance gọn và tập trung:

- ❌ **Mobile app (iOS / Android)** — selection translation trên mobile UX hoàn toàn khác, không tận dụng được code
- ❌ **Browser extension** — Glance đã hoạt động cross-browser qua AX/clipboard, làm extension là duplicate effort
- ❌ **Real-time voice translation** — scope khác, app khác
- ❌ **Document upload + batch translation** — không phải hành vi "instant"
- ❌ **Team / enterprise plans** — không monetize. Nếu cần feature team, fork và tự build
- ❌ **Translation memory chuyên nghiệp (CAT tool)** — có Trados, OmegaT, etc.
- ❌ **Backend riêng** — không có account, không có sync cloud, không có billing

---

## Đóng góp roadmap

Có idea cho roadmap? Mở [feature request issue](https://github.com/nguyenlephong/glance/issues/new?template=feature_request.yml). Idea hay sẽ được thêm vào file này.

Có idea muốn TỰ làm? Mở issue trước để thảo luận thiết kế, sau đó gửi PR. Đọc [CONTRIBUTING.md](../CONTRIBUTING.md).
