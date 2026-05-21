# Glance — Tech Spec

> **Một cái liếc — hiểu mọi ngôn ngữ.**
> Dịch tức thì trên macOS bằng phím tắt, không rời app hiện tại.

---

## 1. Tổng quan

Glance là một macOS menu bar app (LSUIElement, không Dock icon) cung cấp 2 hành động global:

| Hotkey | Hành động |
|---|---|
| `⌃⌥T` | Dịch văn bản đang bôi đen → hiện floating panel cạnh con trỏ |
| `⌃⌥⏎` | Thay đoạn đang bôi đen bằng bản dịch gần nhất |

Engine mặc định: **Google Translate** (free `gtx` endpoint, không cần API key). Toàn bộ logic chạy **on-device**; không có backend riêng. Văn bản chỉ rời máy khi gửi đến Google.

---

## 2. Sơ đồ kiến trúc tổng

```plantuml
@startuml architecture
!theme plain
skinparam componentStyle rectangle
skinparam linetype ortho

package "Glance.app (LSUIElement)" {
  [GlanceApp\n@main] as App
  [AppDelegate\n@MainActor] as Delegate

  package "Hotkey layer" {
    [HotKeyManager\n(Carbon)] as HK
  }

  package "Capture layer" {
    [TextCapture] as TC
    [AccessibilityHelper] as AX
  }

  package "Translation layer" {
    interface Translator
    [GoogleTranslator] as GT
  }

  package "UI layer" {
    [MenuBarController\n(NSStatusItem)] as MB
    [FloatingPanelController] as FPC
    [FloatingPanel\n(NSPanel)] as FP
    [TranslationView\n(SwiftUI)] as TV
    [SettingsView\n(SwiftUI)] as SV
  }

  package "Persistence" {
    [AppSettings\n(UserDefaults)] as Settings
  }
}

cloud "translate.googleapis.com" as GoogleAPI
[macOS Accessibility API] as MacAX
[NSPasteboard] as PB

App --> Delegate
Delegate --> HK : registers ⌃⌥T, ⌃⌥⏎
Delegate --> TC : captureSelectedText()
Delegate --> GT : translate()
Delegate --> FPC : show / present
Delegate --> MB
Delegate --> Settings

TC --> AX
TC --> MacAX : AXSelectedText
TC --> PB : fallback (⌘C simulation)

GT ..|> Translator
GT --> GoogleAPI : HTTPS GET

FPC --> FP
FPC --> TV
MB --> SV

@enduml
```

---

## 3. Layer chi tiết

### 3.1 Hotkey layer — `HotKeyManager`

Singleton bọc Carbon `RegisterEventHotKey`.

- Một `InstallEventHandler` shared cho cả app (lazy install ở lần register đầu).
- Mỗi hotkey có ID duy nhất; handler dispatch theo `EventHotKeyID.id`.
- Hotkey hoạt động kể cả khi app KHÔNG có focus — đó là toàn bộ điểm.

**Nhược điểm cần biết**: Carbon Event Manager là API legacy nhưng vẫn được Apple support. Khi đổi sang Swift 6 strict concurrency có thể cần thêm `@MainActor` annotation.

### 3.2 Capture layer — `TextCapture`

Hai bước theo thứ tự:

1. **Accessibility API** (`AXSelectedTextAttribute` trên focused element). Hoạt động với Safari, TextEdit, Mail, Notes, Xcode, Pages…
2. **Clipboard fallback** (chỉ khi setting `allowClipboardFallback = true`). Hoạt động với Zalo, Slack, VS Code, Chrome, Discord… (đa số app Electron/Chromium).

**An toàn clipboard**:
- Snapshot toàn bộ items + `changeCount` TRƯỚC khi post `⌘C`
- Dùng `CGEventSource(stateID: .privateState)` để OS bỏ qua ⌃⌥ user đang giữ
- **CHỈ** đọc clipboard nếu `changeCount` đã thay đổi (= có copy mới thực sự). Nếu không đổi → trả nil, KHÔNG bao giờ đọc clipboard cũ.
- Restore clipboard ngay sau khi đọc.

### 3.3 Translation layer

```swift
protocol Translator {
    var engine: TranslationEngine { get }
    func translate(
        text: String,
        sourceLanguage: String?,   // nil = auto-detect
        targetLanguage: String
    ) async throws -> TranslationResult
}
```

Hiện chỉ có `GoogleTranslator` (gọi `https://translate.googleapis.com/translate_a/single?client=gtx&sl=...&tl=...&dt=t&q=...`). Endpoint trả về mảng JSON, ta nối các segment `[0]` và đọc detected language ở index `[2]`.

OpenAI / Anthropic sẽ là implement mới của `Translator`, plug-in qua dependency injection ở `AppDelegate`.

### 3.4 UI layer

**`FloatingPanel`** subclass `NSPanel` với:
- `styleMask = [.nonactivatingPanel, .borderless, .fullSizeContentView]`
- `canBecomeKey = false` ⇒ panel KHÔNG steal focus từ app đang dùng
- `level = .floating`
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]`

**`FloatingPanelController`** quản lý lifecycle: present, show loading/result/error, position clamp vào màn hình, auto-dismiss, global dismiss monitor (click ra ngoài / Esc).

**`TranslationView`** SwiftUI: header pills + swap, content (loading/text/error), actions bar (Replace filled accent / Copy / Dismiss).

### 3.5 Persistence — `AppSettings`

`@MainActor` ObservableObject singleton, store trong `UserDefaults`:

| Key | Type | Default | Mô tả |
|---|---|---|---|
| `glance.engine` | `TranslationEngine` | `.google` | Engine dịch |
| `glance.primaryLanguage` | `String` | `vi` | Ngôn ngữ chính của user |
| `glance.secondaryLanguage` | `String` | `en` | Ngôn ngữ phụ |
| `glance.saveHistory` | `Bool` | `false` | Lưu lịch sử (chưa implement) |
| `glance.uiLanguage` | `String` | `vi` | UI Vietnamese/English |
| `glance.allowClipboardFallback` | `Bool` | `true` | Cho phép giả lập ⌘C |
| `glance.autoDismissSeconds` | `Int` | `60` | Auto-dismiss timeout (0 = never) |

---

## 4. Flow chính

### 4.1 Flow: Dịch text bôi đen (⌃⌥T)

```plantuml
@startuml translate-flow
!theme plain
autonumber

actor User
participant "macOS\n(Carbon)" as OS
participant "HotKeyManager" as HK
participant "AppDelegate" as AD
participant "TextCapture" as TC
participant "Accessibility\nAPI" as AX
participant "NSPasteboard" as PB
participant "GoogleTranslator" as GT
participant "translate.googleapis.com" as Google
participant "FloatingPanelController" as FPC
participant "TranslationView" as TV

User -> User : Bôi đen text trong app bất kỳ
User -> OS : Bấm ⌃⌥T
OS -> HK : Carbon event\n(EventHotKeyID id=1)
HK -> AD : handleTranslateHotKey()

AD -> FPC : showLoading(at: mousePos)
FPC -> TV : state = .loading

AD -> TC : captureSelectedText(allowClipboardFallback)
TC -> AX : AXSelectedText
alt AX trả về text
  AX --> TC : "Hello world"
else AX nil + fallback on
  TC -> PB : snapshot + changeCount
  TC -> OS : simulate ⌘C (.privateState)
  TC -> PB : poll changeCount
  alt changeCount tăng
    PB --> TC : "Hello world"
  else không đổi
    TC --> AD : throws .noSelection
    AD -> FPC : presentError(...)
    FPC -> TV : state = .failure(msg)
  end
  TC -> PB : restore snapshot
end
TC --> AD : "Hello world"

AD -> GT : translate(text, sourceLang: nil, targetLang: "vi")
GT -> Google : GET ?sl=auto&tl=vi&q=Hello+world
Google --> GT : [[["Xin chào thế giới","Hello world",...]],...,"en",...]
GT --> AD : TranslationResult(sourceLang: "en", target: "vi", text: "Xin chào thế giới")

note over AD: Nếu detected source == target\n→ dịch lần 2 sang ngôn ngữ còn lại trong cặp\n(xem flow Auto-direction)

AD -> FPC : showResult(result)
FPC -> TV : state = .success(result)
FPC -> FPC : scheduleAutoDismiss(autoDismissSeconds)

User -> User : Đọc kết quả

@enduml
```

### 4.2 Flow: Auto-direction (đảo chiều thông minh)

```plantuml
@startuml auto-direction
!theme plain
autonumber

participant "AppDelegate" as AD
participant "AppSettings" as S
participant "GoogleTranslator" as GT

note over AD: User bôi đen 1 đoạn tiếng Việt\nvới settings: primary=vi, secondary=en

AD -> GT : translate(text, sourceLang: nil, targetLang: "vi")
note right: Lần 1: dùng primary làm target\nđể Google trả về detectedLang
GT --> AD : result(sourceLang: "vi", target: "vi", text: <unchanged>)

AD -> AD : sameLanguage("vi", "vi") == true
AD -> S : preferredTarget(forDetectedSource: "vi")
S --> AD : "en"  (secondary)
AD -> AD : sameLanguage("en", "vi") == false → cần dịch lại

AD -> GT : translate(text, sourceLang: "vi", targetLang: "en")
note right: Lần 2: force source + target rõ ràng
GT --> AD : result(sourceLang: "vi", target: "en", text: "translated")

AD -> AD : panelController.showResult(second)

@enduml
```

### 4.3 Flow: Replace text bôi đen (⌃⌥⏎ hoặc nút Replace)

```plantuml
@startuml replace-flow
!theme plain
autonumber

actor User
participant "OS / Button" as Trigger
participant "AppDelegate" as AD
participant "FloatingPanelController" as FPC
participant "NSPasteboard" as PB
participant "OS event tap" as OS
participant "App gốc\n(Zalo / Mail / …)" as TargetApp

note over User: Panel đang hiện bản dịch "Xin chào thế giới"\ncho text "Hello world" đã bôi đen
User -> Trigger : Bấm ⌃⌥⏎\nhoặc nút Replace
Trigger -> AD : replaceSelectedText()

AD -> FPC : lastTranslation?
FPC --> AD : TranslationResult(text: "Xin chào thế giới")

AD -> AD : pasteText("Xin chào thế giới")
AD -> PB : snapshot items + types
AD -> PB : clear + setString("Xin chào thế giới")
AD -> FPC : dismissImmediately()
note right: Panel đã không steal focus,\nnhưng đóng nhanh để chắc chắn\nfocus về app gốc

AD -> AD : sleep 70ms (chờ user nhả phím)
AD -> OS : CGEvent ⌘V (.privateState)
OS -> TargetApp : Paste event
TargetApp -> TargetApp : Replace selection bằng\n"Xin chào thế giới"

AD -> AD : sleep 250ms (chờ paste hoàn tất)
AD -> PB : restore snapshot
note right: Clipboard cũ của user\nđược khôi phục — user không\nbiết Glance từng động vào

@enduml
```

### 4.4 State diagram: Floating panel

```plantuml
@startuml panel-states
!theme plain

[*] --> Hidden

Hidden --> Loading : showLoading(at:)
Loading --> Success : showResult(result)
Loading --> Failure : showError(msg)

Success --> Hidden : Esc / click outside\n/ auto-dismiss timeout
Success --> Loading : swap / re-translate
Success --> Hidden : Replace triggered\n→ dismissImmediately()

Failure --> Hidden : Esc / click outside\n/ auto-dismiss (max 15s)

Hidden --> Failure : presentError(at:)\nkhi AX/capture lỗi

@enduml
```

---

## 5. Tương tác với macOS — quyền & rủi ro

### Quyền Accessibility (`AXIsProcessTrusted`)

Bắt buộc cho:
1. `AXUIElementCopyAttributeValue` đọc `AXSelectedTextAttribute`
2. `CGEvent.post(tap: .cghidEventTap)` để giả lập `⌘C` và `⌘V`

App tự gọi `AXIsProcessTrustedWithOptions(prompt: true)` lúc launch.

### Không cần Screen Recording

Hiện tại MVP không có OCR. Khi thêm Vision `VNRecognizeTextRequest` sẽ cần Screen Recording.

### Không App Sandbox

`com.apple.security.app-sandbox = false` để có quyền:
- Đọc Accessibility tree của process khác
- Đăng ký global hotkey
- Đọc/ghi `NSPasteboard.general`

Nghĩa là app KHÔNG submit được lên Mac App Store. Distribute qua DMG + Apple Developer ID notarization.

---

## 6. Hotkey table

| Hotkey | Scope | Hành động |
|---|---|---|
| `⌃⌥T` | Global | Translate text đang bôi đen |
| `⌃⌥⏎` | Global | Replace text đang bôi đen bằng `lastTranslation` |
| `Esc` | Khi panel có focus tạm thời | Đóng panel |
| `⌘,` | Khi menu mở | Mở Settings |
| `⌘Q` | Khi menu mở | Thoát app |

**Tại sao `⌃⌥⏎` cho Replace**: cùng modifier chord với `⌃⌥T`, ngón tay đã sẵn ở đó, chỉ đổi T → Enter. Muscle memory ngắn nhất.

---

## 7. Quyết định thiết kế (ADR-style)

### ADR-1: Dùng Carbon `RegisterEventHotKey` thay vì `NSEvent.addGlobalMonitor`

- `addGlobalMonitor` chỉ observe, KHÔNG suppress được phím → ⌃⌥T sẽ leak ký tự "†" (Option+T) vào app đang focus.
- `RegisterEventHotKey` suppress đúng cách. Carbon vẫn được Apple support.

### ADR-2: Clipboard fallback dùng strict `changeCount` check

- Vấn đề thực tế: nhiều app Electron không phơi bày `AXSelectedTextAttribute`.
- Vấn đề privacy ban đầu: code cũ rớt về clipboard cũ → lộ data nhạy cảm.
- Fix: chỉ đọc clipboard nếu `changeCount` tăng. Snapshot+restore an toàn.

### ADR-3: Replace dùng `⌘V` simulation thay vì AX `setValue`

- AX `setValue(kAXSelectedTextAttribute)` chỉ hoạt động với app có AX text role — y hệt set Electron không hỗ trợ.
- `⌘V` simulation hoạt động với mọi text field — universal.
- Phải snapshot + restore clipboard để giữ trải nghiệm trong sạch.

### ADR-4: `NSPanel` nonactivating thay vì `NSWindow`

- Panel hiện ra KHÔNG được steal focus → khi user bấm Replace, focus vẫn ở app gốc, `⌘V` vào đúng chỗ.
- Tradeoff: SwiftUI `.keyboardShortcut` chỉ hoạt động khi window là key. Vì panel không key → Replace shortcut phải đi qua global Carbon hotkey, không phải SwiftUI shortcut.

### ADR-5: XcodeGen thay vì commit `.xcodeproj`

- `project.yml` đọc được, diff được, không bị merge conflict trên `.pbxproj`.
- Onboarding: `brew install xcodegen && xcodegen generate`.

---

## 8. Lộ trình mở rộng

| Feature | Layer ảnh hưởng | Ghi chú |
|---|---|---|
| OpenAI / Anthropic engine | `Translator` impl mới + Keychain | API key user nhập, store Keychain, dropdown engine ở Settings |
| Streaming SSE | `TranslationView` (incremental update) + `Translator` (AsyncSequence) | Cho AI engine |
| OCR | Vision framework + Screen Recording permission | Hotkey thứ 3: ⌃⌥O = chụp vùng + OCR + dịch |
| Local history | SQLite ở `~/Library/Application Support/Glance` | Bật/tắt theo `saveHistory` |
| Custom hotkey | UI ghi `keyCode` + `modifiers` vào Settings | `HotKeyManager.unregister(id)` + register lại |
| Context-aware prompt | Bổ sung field "context" vào `Translator.translate(...)` | AI engine dùng để adjust tone |
| Sparkle auto-update | Sparkle SDK + Apple Developer ID + notarization | Trước khi public release |

---

## 9. Render PlantUML

Các block `plantuml` trong tài liệu này render được bằng:

- VS Code extension: `jebbs.plantuml`
- IntelliJ / Xcode plugin
- Online: https://www.plantuml.com/plantuml/uml

Hoặc local CLI:

```bash
brew install plantuml
plantuml -tsvg docs/TECH_SPEC.md
```
