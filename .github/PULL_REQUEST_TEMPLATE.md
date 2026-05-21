<!--
Cảm ơn anh/chị đã gửi PR cho Glance.
Vui lòng điền các mục dưới đây — giúp review nhanh hơn.
Có thể xoá những section không liên quan.
-->

## Vấn đề đang giải quyết

<!-- Link issue nếu có: "Closes #123" hoặc "Refs #45" -->
<!-- Hoặc mô tả ngắn 1–2 câu nếu chưa có issue -->

## Thay đổi gì

<!-- List ngắn:
- Thêm OpenAI translator (file mới `OpenAITranslator.swift`)
- Đổi `AppSettings` thêm field `openaiApiKey` lưu Keychain
- UI Settings có ô nhập API key
-->

## Đã test thế nào

<!-- Bắt buộc — kiểm tra ít nhất 3 app, vì AX và Electron có behavior khác nhau:
- [ ] Safari (AX path)
- [ ] TextEdit (AX path)
- [ ] Chrome / Zalo / VS Code (clipboard fallback path)
- [ ] Replace flow (⌃⌥⏎) trong ít nhất 2 app
-->

- [ ] Build pass: `cd apps/macos && xcodegen generate && xcodebuild build`
- [ ] Đã chạy bản build thủ công và verify behavior
- [ ] Đã update tài liệu liên quan (`README.md`, `CHANGELOG.md`, `docs/TECH_SPEC.md`)

## Ảnh chụp / GIF (nếu thay đổi UI)

<!-- Drag-drop vào đây -->

## Checklist cuối

- [ ] Commit message theo [Conventional Commits](https://www.conventionalcommits.org/) (feat / fix / docs / refactor / chore / perf)
- [ ] Không commit file generated (`.xcodeproj/`, `build/`, `dist/`, `.DS_Store`)
- [ ] Không commit secrets / API key
- [ ] Đã đọc [CONTRIBUTING.md](../CONTRIBUTING.md)
