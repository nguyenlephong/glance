# Cài Glance trên macOS

> **Một cái liếc — hiểu mọi ngôn ngữ.**

## Yêu cầu

- **macOS 13 (Ventura) trở lên**
- Chạy được trên cả **Apple Silicon (M1/M2/M3/M4)** và **Intel** (universal binary)

## Cài đặt (3 bước)

### Bước 1 — Mở file `.dmg`

Double-click `Glance-0.1.0.dmg` → cửa sổ Finder hiện ra với icon Glance và shortcut Applications.
Kéo `Glance.app` vào thư mục `Applications`.

### Bước 2 — Mở app lần đầu (bypass Gatekeeper)

App này **chưa được Apple notarize** (vì không trả phí Apple Developer Program $99/năm), nên macOS sẽ chặn lần đầu với thông báo kiểu:

> *"Glance" cannot be opened because Apple cannot check it for malicious software.*
> hoặc *"Glance" is damaged and can't be opened. You should move it to the Trash.*

Đừng lo — app vẫn an toàn (anh có thể đọc source code). Có 2 cách bypass:

#### Cách A — Right-click → Open (đơn giản nhất)

1. Vào `Applications` (Finder)
2. **Right-click** (hoặc Control + click) vào `Glance.app`
3. Chọn **Open**
4. Dialog hiện ra → bấm **Open** lần nữa
5. App chạy. Lần sau mở bằng double-click bình thường.

> Nếu dialog không có nút "Open" mà chỉ có "Move to Trash" → dùng Cách B.

#### Cách B — Terminal (nếu Cách A không được)

Mở Terminal (`/Applications/Utilities/Terminal.app`), paste lệnh:

```bash
xattr -dr com.apple.quarantine /Applications/Glance.app
```

Bấm Enter → mở lại Glance bằng double-click bình thường.

> Lệnh trên xoá flag "downloaded from internet" trên file. An toàn.

#### Cách C — System Settings (macOS 13+)

1. Double-click `Glance.app` → macOS chặn
2. Mở **System Settings → Privacy & Security**
3. Cuộn xuống mục **Security** → thấy "Glance was blocked…"
4. Bấm **Open Anyway** → nhập password
5. Mở lại Glance — bấm **Open**

### Bước 3 — Cấp quyền Accessibility

Glance cần quyền **Accessibility** để:
- Đọc văn bản đang được bôi đen ở app khác
- Giả lập `⌘C` / `⌘V` cho fallback và Replace

Lần đầu chạy, app sẽ tự bật prompt. Nếu lỡ bỏ qua:

1. Mở **System Settings → Privacy & Security → Accessibility**
2. Bấm `+` → chọn `Glance.app` trong `Applications`
3. Bật toggle bên cạnh **Glance**
4. Quit Glance hoàn toàn (menu bar icon → Thoát Glance) và mở lại

## Cách dùng

| Hotkey | Hành động |
|---|---|
| `⌃⌥T` (Control + Option + T) | Dịch text đang bôi đen — panel hiện cạnh con trỏ |
| `⌃⌥⏎` (Control + Option + Enter) | Thay text đang bôi đen bằng bản dịch gần nhất |
| `Esc` (khi panel hiện) | Đóng panel |

Click icon Glance trên menu bar (góc trên phải) để mở **Cài đặt** hoặc **Thoát**.

## Cài đặt khuyến nghị

Settings → Tổng quan:
- **Tự đóng sau**: 1 phút (mặc định) — chỉnh lên 5 phút hoặc "Không tự tắt" nếu thường đọc kết quả lâu
- **Hỗ trợ app Electron**: ✅ bật (đã bật sẵn) — cần thiết cho Zalo, Slack, VS Code, Chrome

Settings → Dịch:
- **Ngôn ngữ chính**: Tiếng Việt
- **Ngôn ngữ phụ**: Tiếng Anh
- Glance tự nhận chiều: text tiếng Anh → dịch sang Việt, text Việt → dịch sang Anh

## Test thử

1. Mở Safari, bôi đen 1 câu tiếng Anh bất kỳ
2. Bấm `⌃⌥T` → thấy panel hiện bản dịch Việt
3. Bấm nút **Replace** hoặc `⌃⌥⏎` → câu tiếng Anh bị thay bằng tiếng Việt

Nếu trong Safari OK nhưng Zalo / Chrome không lấy được text → kiểm tra Accessibility đã bật chưa, hoặc bật setting **"Hỗ trợ app Electron"**.

## Cập nhật

Tải file `.dmg` mới hơn, kéo `Glance.app` vào `Applications` đè lên bản cũ. macOS sẽ hỏi confirm replace — bấm **Replace**.

## Gỡ cài

1. Quit Glance từ menu bar → **Thoát Glance**
2. Kéo `/Applications/Glance.app` vào Trash
3. (Tuỳ chọn) Xoá settings: `defaults delete app.glance.mac`
4. (Tuỳ chọn) Xoá khỏi danh sách Accessibility: System Settings → Accessibility → chọn Glance → bấm `−`

## Vấn đề thường gặp

| Triệu chứng | Cách xử lý |
|---|---|
| "is damaged and can't be opened" | Chạy `xattr -dr com.apple.quarantine /Applications/Glance.app` |
| Bấm ⌃⌥T không có gì xảy ra | Kiểm tra Accessibility đã bật, quit + mở lại Glance |
| Lấy text được ở Safari nhưng không được ở Chrome/Zalo | Bật setting "Hỗ trợ app Electron" trong Cài đặt |
| Panel hiện quá nhanh, chưa kịp đọc | Settings → "Tự đóng sau" → chọn 2 phút / 5 phút / Không tự tắt |
| Hotkey ⌃⌥T trùng app khác | Phiên bản hiện tại chưa cho custom hotkey, sẽ có ở bản sau |

## Báo lỗi / góp ý

Liên hệ tác giả qua kênh đã share file. Khi báo lỗi vui lòng cho biết:
- Phiên bản macOS
- App đang dùng khi gặp lỗi
- Mô tả ngắn gì đang xảy ra
