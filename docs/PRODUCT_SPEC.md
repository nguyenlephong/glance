# 🧠 AI Agent Prompt: Build a Desktop Instant Translation App (HotLingo Clone)

## 🎯 Project Goal

Build a **native desktop application** for **macOS** that lets users translate any text on screen instantly
via a global hotkey — without ever leaving their current app. A floating translation panel appears next to the cursor
with the result. The app is free to use out of the box via Google Translate, and optionally supports AI-powered
translation through user-provided API keys.

---

## 🖥️ Target Platforms

- **macOS 13+** (Ventura and above)

---

## 👤 Target Users

- Vietnamese users who regularly read and work with foreign-language content (English, etc.)
- Developers, researchers, business professionals, students
- People who chat with foreign colleagues in Slack, Zalo, Telegram, Messenger
- Anyone who reads PDFs, documents, or websites in a foreign language

---

## ✅ Core Features

### Feature 1 — Quick Translate (Text Selection)

- User **highlights/selects any text** in any app (browser, PDF, Slack, email, IDE, game, etc.)
- User presses the **global hotkey** `Ctrl+Alt+T` (Windows) / `⌃⌥T` (macOS)
- A **floating translation panel** instantly appears next to the cursor/selected text
- Shows the translation result inline — user never switches windows or tabs
- Works system-wide across all apps
- Requires **Accessibility permission** on macOS

### Feature 3 — Floating Translation Panel (UI Component)

- A **small, lightweight overlay window** that floats above all other windows
- Appears at/near the cursor or selected text position
- Panel content:
    - Detected source language label
    - Target language label
    - Translation result text (supports streaming for AI responses)
    - AI streaming indicator animation (when using AI engine)
    - Source engine badge: `Google` / `OpenAI` / `Anthropic`
- Dismisses on: click outside, `Escape` key, or auto-timeout
- Does **not steal focus** from the current application
- Smooth fade-in animation < 150ms

### Feature 4 — Translation Engine Selection

| Engine                  | Auth Required      | Cost Model                   |
|-------------------------|--------------------|------------------------------|
| Google Translate        | None               | Free, unlimited              |
| OpenAI (GPT-4o / GPT-4) | User's own API key | User pays OpenAI directly    |
| Anthropic Claude        | User's own API key | User pays Anthropic directly |

- **Default engine on fresh install**: Google Translate (zero config, works immediately)
- API keys entered by user in Settings — stored **locally only**, never sent to app servers
- Engine can be switched anytime from Settings

### Feature 5 — Context-Aware AI Translation

- Optional **context input field** in the floating panel or Settings
- User can type a domain hint before translating:
    - Examples: `"Legal contract"`, `"Technical documentation"`, `"Medical report"`, `"Casual chat"`, `"Literature"`
- AI uses this context to adjust tone, terminology, and translation style
- Context can be saved as a preset for repeated use

### Feature 7 — Settings Panel

- Choose translation engine (Google / OpenAI / Anthropic / App Credits)
- Input and save API keys (OpenAI, Anthropic) — stored in local keychain/secure storage
- Customize hotkeys for Quick Translate
- Set default target language (default: Vietnamese)
- Toggle local history storage on/off
- Language switcher for app UI: Vietnamese ↔ English

### Feature 8 — Local Translation History

- Optional on-device history log of past translations
- User can browse, search, copy, and delete history entries
- History is **never synced to any server**
- Stored in local SQLite or flat file

---

## 🔄 User Flow

### Flow A: Text Selection → Translation

```
1. User reads content in any app
2. User selects/highlights text with mouse or keyboard
3. User presses ⌃⌥T (or Ctrl+Alt+T)
4. Captures selected text via Accessibility API or Clipboard
5. App sends text to chosen translation engine
6. Floating panel appears near cursor with translation result
7. User reads result, clicks away or presses Escape to dismiss
```


### Flow A: Zero-Config First Launch

```
1. User downloads and installs app
2. App requests Accessibility + Screen Recording permissions (macOS)
3. No login, no account creation required
4. Google Translate works immediately
5. Optional: user enters API key in Settings for AI translation
```

---

## 🏗️ Technical Architecture

### macOS Implementation

- **Language**: Swift / SwiftUI
- **Global hotkey**: `CGEventTap` (low-level input hook, no focus change)
- **Text capture**: Accessibility API (`AXUIElement`) to read selected text from frontmost app; fallback to clipboard (
  `NSPasteboard`)
- **OCR**: Apple Vision (`VNRecognizeTextRequest`) — on-device, no internet needed for OCR
- **Floating window**: `NSPanel` with `NSFloatingWindowLevel`, `canBecomeKey = false`, transparent background, rounded
  corners via `CALayer`
- **HTTP calls**: `URLSession` for Google Translate / OpenAI API / Anthropic API
- **Streaming**: Server-Sent Events (SSE) parsing for OpenAI streaming responses
- **Secure storage**: macOS Keychain for API keys
- **Menu bar app**: `NSStatusItem` with no Dock icon (`LSUIElement = YES` in Info.plist)
- **Auto-update**: Sparkle framework

### Cross-Platform Alternative (Electron)

- **Framework**: Electron + Node.js
- **Global hotkey**: `globalShortcut` Electron API
- **Text capture**: `robotjs` or `@nut-tree/nut-js`
- **OCR**: Tesseract.js or native bridge to system OCR
- **Floating window**: Electron `BrowserWindow` with `alwaysOnTop`, `frame: false`, `transparent: true`
- **Streaming**: `fetch` with `ReadableStream` for SSE

### Translation API Integration

```
Google Translate (Free):
  GET https://translate.googleapis.com/translate_a/single
  ?client=gtx&sl=auto&tl=vi&dt=t&q={text}

OpenAI (User API Key):
  POST https://api.openai.com/v1/chat/completions
  Headers: Authorization: Bearer {user_api_key}
  Body: { model: "gpt-4o", stream: true, messages: [...] }

Anthropic (User API Key):
  POST https://api.anthropic.com/v1/messages
  Headers: x-api-key: {user_api_key}
  Body: { model: "claude-3-5-sonnet", stream: true, messages: [...] }
```

---

## 🎨 UI / UX Design Specification

### Overall Design Language

- **Minimal, non-intrusive** — never distracts from user's main work
- Follows OS dark/light mode automatically
- Primary accent color: **dark green** (`#1B5E20` / `#2D6A4F` range)
- Secondary: off-white, light gray backgrounds
- Typography: system font (`SF Pro` on macOS, `Segoe UI` on Windows)

### Floating Translation Panel

- Width: 320–400px, height: auto
- Background: `rgba(255,255,255,0.95)` light / `rgba(30,30,30,0.95)` dark
- Border-radius: 12px
- Box-shadow: `0 8px 32px rgba(0,0,0,0.18)`
- Padding: 16px
- Sections:
    - Top bar: source language → target language + engine badge
    - Translation text: 14–16px, line-height 1.6
    - Streaming indicator: animated dots while AI is typing
    - Optional: copy button, speak button
- Fade-in animation: `opacity 0 → 1` over 120ms
- Appears at cursor position + small offset (12px right, 8px down)
- Repositions if near screen edge to stay fully visible

### Menu Bar / System Tray Icon

- Small icon (16×16 or 18×18): stylized "A↔" or translation symbol
- Click to open Settings
- Right-click for quick menu: engine selector, toggle on/off, history, quit

### Settings Window

- Sidebar navigation: General / Translation / Hotkeys / Account / About
- Clean form layout with section headers
- Toggle switches for boolean settings
- Inline API key input with show/hide toggle and validation indicator

### Onboarding (First Launch)

- 3-step walkthrough overlay:
    1. "Select any text" — animated cursor demo
    2. "Press the hotkey" — keyboard visual
    3. "Read translation" — floating panel demo
- Skip button always visible
- Requests Accessibility + Screen Recording permissions with clear explanation

---

## 🔐 Privacy & Security Requirements

- Translated text is **NOT stored on servers** after translation completes
- API keys stored in **OS-level secure storage** (Keychain / Credential Manager), never in plain files
- Local history stored **on-device only** (SQLite), never synced
- OCR on macOS uses **Apple Vision** — fully on-device, zero network for OCR step
- App **never reads clipboard** without explicit user action
- Privacy policy must disclose: what data is sent to translation APIs (the text being translated)
- Users can clear all local data from Settings at any time

---

## 📦 Distribution & Installation

### macOS

- Format: `.dmg` disk image with drag-to-Applications install
- **Not** Mac App Store (Accessibility API restrictions)
- Code-signed with Apple Developer ID
- Notarized by Apple
- Auto-update via Sparkle framework


### Website (Marketing Landing Page)

Must include these sections:

1. **Hero** — headline, subheadline, CTA download button, demo GIF/video
2. **Features** — 3–6 feature cards with icons and screenshots
3. **How It Works** — numbered 3-step flow with illustrations
4. **Powered By** — Anthropic / OpenAI / Google logos
5. **Pricing** — 3-tier credit pack cards (Small / Medium / Large)
6. **FAQ** — accordion, at least 10 questions
7. **Footer** — links: Features, How to Use, AI, FAQ, Download, Terms, Privacy, Refund Policy, Support email, Zalo
   group, GitHub

---

## 🌐 Localization

- App UI primary language: **Vietnamese**
- App UI secondary language: **English** (toggle in top-right of navbar)
- Translation target default: Vietnamese
- Google Translate: 100+ languages
- AI models: all major languages (EN, JA, KO, ZH, FR, DE, ES, etc.)
- Vietnamese translation quality = **highest priority** for AI prompt tuning

---

## 🚫 Out of Scope (V1)

- Mobile app (iOS / Android)
- Browser extension
- Real-time voice / conversation translation
- Document upload & batch translation
- Team / enterprise plans
- Offline translation (no internet mode)
- Translation memory / glossary management

---

## 📊 Success Metrics

| Metric                    | Goal                            |
|---------------------------|---------------------------------|
| Downloads                 | Track total installs            |
| DAU (hotkey triggers)     | Active daily translation events |
| Engine usage split        | % Google vs AI                  |
| OCR usage rate            | % users using OCR feature       |
| Credit conversion rate    | % free users buying credits     |
| Avg translations/user/day | Engagement depth                |

---

## 🗂️ Project File Structure (Suggested)

```
/app
  /macos          → Swift/SwiftUI macOS app
  /windows        → C#/WPF Windows app
/backend          → Optional: credit purchase API, auth
/website          → Landing page (Next.js / Astro recommended)
/shared
  /translation    → Translation engine adapters (Google, OpenAI, Anthropic)
  /ocr            → OCR wrappers
/assets           → Icons, screenshots, demo GIFs
README.md
```

---

## ⚙️ Environment Variables / Config

```env
# Google Translate (no key needed for free tier)
GOOGLE_TRANSLATE_ENDPOINT=https://translate.googleapis.com/translate_a/single

# OpenAI (user provides their own key — stored in Keychain)
OPENAI_API_ENDPOINT=https://api.openai.com/v1/chat/completions

# Anthropic (user provides their own key — stored in Keychain)
ANTHROPIC_API_ENDPOINT=https://api.anthropic.com/v1/messages

# App backend (for credit system)
BACKEND_API_URL=https://api.yourapp.com
```

---

## ✅ Definition of Done (DoD)

- [ ] Global hotkey triggers translation from any app without stealing focus
- [ ] Floating panel appears at cursor position within < 1 second
- [ ] OCR captures and translates screen region correctly
- [ ] Google Translate works on fresh install with zero configuration
- [ ] User can enter OpenAI / Anthropic API key and use AI translation
- [ ] AI streaming responses display progressively in floating panel
- [ ] Settings persisted across app restarts
- [ ] API keys stored securely (Keychain / Credential Manager)
- [ ] App lives in menu bar / system tray with no Dock icon
- [ ] macOS permissions flow (Accessibility + Screen Recording) explained clearly
- [ ] Auto-update works silently in background
- [ ] App passes macOS notarization
- [ ] Landing page deployed with all required sections
- [ ] Privacy policy published and linked