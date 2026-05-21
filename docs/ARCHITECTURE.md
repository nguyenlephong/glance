# Glance — Kiến trúc tổng

> Tài liệu này nói về **cách Glance tổ chức code ở mức repo** — đặc biệt là việc giữ macOS, Windows (tương lai), và bất kỳ platform nào khác cùng tồn tại lành mạnh trong một mono-repo.
>
> Nếu anh/chị tìm chi tiết internals của bản macOS (flow, sequence diagram, ADR) → đọc [`apps/macos/docs/TECH_SPEC.md`](../apps/macos/docs/TECH_SPEC.md).

---

## Triết lý

Glance là một **product nhỏ làm một việc**: bôi đen text → bấm hotkey → đọc bản dịch. Toàn bộ kiến trúc phải phục vụ trải nghiệm đó. Bất kỳ độ phức tạp nào không tạo ra giá trị cho hành động hai-bước này đều là nợ kỹ thuật.

Bốn nguyên tắc:

1. **Native trước, framework sau** — mỗi platform dùng UI toolkit native của OS đó (SwiftUI/AppKit cho macOS, WPF hoặc WinUI cho Windows…). Không cố ép một framework cross-platform vì hai lý do: (1) hotkey, accessibility, floating window đều cần platform-specific code dù dùng framework gì, và (2) binary size + cảm giác native quan trọng cho menu bar app.

2. **Shared là spec, không phải code** — các platform chia sẻ *contract* (giao thức translation API, định nghĩa hotkey, UX spec của floating panel), không phải Swift/C#/Rust code. Mỗi platform tự implement.

3. **Privacy by design** — không telemetry, không tracking, không account. Văn bản dịch chỉ rời máy khi gửi đến engine user chọn. Mọi thiết kế tính năng phải bắt đầu bằng câu hỏi "user nhạy cảm với gì?".

4. **Solo-maintainable** — Glance phải xây sao cho một người có thể duy trì được trong vài năm. Tránh sub-module, monorepo tool phức tạp, generator code nặng. Plain folder + plain build script.

---

## Cấu trúc thư mục

```
glance/
├── apps/
│   └── macos/             ← Bản native macOS (hiện có)
│       ├── Sources/       ← Swift code
│       ├── Resources/     ← Info.plist (XcodeGen sinh)
│       ├── project.yml    ← XcodeGen — generate .xcodeproj
│       ├── scripts/       ← release.sh build DMG
│       ├── docs/          ← Tech spec của riêng macOS
│       ├── INSTALL.md     ← Hướng dẫn cho end user macOS
│       └── README.md      ← Dev quick start cho platform này
├── docs/                  ← Cross-platform docs (file này, ROADMAP, SPEC gốc)
├── assets/                ← Screenshot, demo GIF (chung)
├── .github/               ← Issue/PR template, CI workflow
└── (LICENSE / CONTRIBUTING / CODE_OF_CONDUCT / CHANGELOG / README)
```

### Quy ước

- **`apps/<platform>/`** — mỗi platform là một project độc lập, có thể build riêng. Một developer chỉ làm Windows không cần biết Swift.
- **`apps/<platform>/docs/`** — docs riêng cho platform (tech spec, ADR nội bộ)
- **`docs/`** — docs chung (kiến trúc tổng, roadmap, spec sản phẩm)
- **CI** trong `.github/workflows/` chia thành các job theo platform: `build-macos.yml`, sau này sẽ có `build-windows.yml`. Mỗi job chỉ chạy khi file của platform tương ứng thay đổi (path filter)

---

## Quan hệ giữa các platform

```
       ┌────────────────────────────────────────────┐
       │           SPEC (docs/, README)             │
       │  Translation contract, UX rules, hotkeys,  │
       │  privacy guarantees                         │
       └────────────────────────────────────────────┘
                          │
              ┌───────────┼──────────────┐
              ▼           ▼              ▼
        ┌─────────┐  ┌─────────┐   ┌──────────┐
        │ macOS   │  │ Windows │   │ Linux    │
        │ Swift   │  │ (TBD)   │   │ (TBD)    │
        │ AppKit  │  │ WPF? /  │   │ Tauri? / │
        │ SwiftUI │  │ Tauri?  │   │ GTK?     │
        └─────────┘  └─────────┘   └──────────┘
```

Mỗi implementation độc lập, miễn là tuân thủ contract chung:

- **Hotkey mặc định**: `Control+Option+T` (macOS) → `Ctrl+Alt+T` (Windows/Linux)
- **Replace hotkey**: `Control+Option+Enter` (macOS) → `Ctrl+Alt+Enter` (Windows/Linux)
- **Engine API contract**: xem `Translator` protocol ở [`apps/macos/Sources/Translator.swift`](../apps/macos/Sources/Translator.swift) — đây là tham chiếu, port sang ngôn ngữ khác giữ semantics tương đương
- **Privacy guarantee**: clipboard snapshot + restore + strict `changeCount` check. Không bao giờ leak old clipboard
- **UX**: floating window không steal focus, hiện cạnh con trỏ, auto-dismiss (timeout configurable)

---

## Lựa chọn công nghệ cho platform tương lai

Khi port sang platform mới, đánh giá theo 4 tiêu chí: (1) hỗ trợ global hotkey suppression, (2) hỗ trợ floating window không steal focus, (3) accessibility API tương đương AX, (4) binary size & cảm giác native.

### Windows — gợi ý

| Stack | Hotkey | Floating | AX | Native | Ghi chú |
|---|---|---|---|---|---|
| C#/WPF + Win32 API | `RegisterHotKey` ✓ | WPF Window topmost ✓ | UI Automation ✓ | ✓ Tốt | Cách "chính thống" Windows |
| C#/WinUI 3 | ✓ qua interop | ✓ | ✓ | ✓ Modern | UI Windows 11-feel |
| Tauri (Rust + WebView) | ✓ qua plugin | ✓ | △ phụ thuộc OS | Web | Cross-platform sẵn, binary nhỏ |
| Electron | ✓ | ✓ | △ | ✗ Heavy (100+ MB) | Tránh nếu được |

Khuyến nghị: **C#/WinUI 3** hoặc **Tauri**. Tránh Electron vì trái với triết lý "menu bar app nhỏ".

### Linux — gợi ý

Phức tạp hơn vì có nhiều DE (GNOME, KDE, hybrid), Wayland vs X11 khác hành vi global hotkey hoàn toàn. Hướng:

- **Tauri** + portal-based hotkey — hỗ trợ Wayland qua xdg-desktop-portal
- **GTK4** + libayatana-appindicator — nếu muốn native GNOME

---

## Quyết định kiến trúc đã chốt

Chi tiết ADR (Architecture Decision Records) cho riêng macOS ở [`apps/macos/docs/TECH_SPEC.md` §7](../apps/macos/docs/TECH_SPEC.md). Ở mức repo, các quyết định lớn:

- **Mono-repo thay vì multi-repo** — chia sẻ docs và issue tracker. Khi project nhỏ, một repo dễ hơn nhiều repo
- **Không dùng monorepo tool (Nx, Turborepo)** — không cần caching cross-platform vì mỗi platform có toolchain riêng. Plain folders + per-platform build scripts là đủ
- **Mỗi platform có CI riêng** — `.github/workflows/build-<platform>.yml`, path-filtered để không trigger nhau
- **Releases dùng GitHub Releases** thay vì hosting riêng — đơn giản, miễn phí, có changelog tự động
