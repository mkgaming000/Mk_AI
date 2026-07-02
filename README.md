# ⚡ OmniForge AI

**The most advanced AI super app for Android.**
12 AI chat providers · local model support · agents with real tool use · 98 source files.

---

## 🚀 Features

### AI Chat
- **12 providers**: OpenAI (GPT-4o, o1, o3-mini), Anthropic (Claude Opus/Sonnet/Haiku), Google Gemini, xAI Grok, DeepSeek (with visible reasoning), Mistral, OpenRouter (1000+ models), HuggingFace Inference, Together AI (Llama), Alibaba Qwen, Ollama (local), LM Studio (local)
- Real-time SSE streaming with a live "thinking" panel for models that expose reasoning (Claude extended thinking, DeepSeek R1)
- A **Streaming Responses** setting: turn it off to receive the full reply at once instead of token-by-token
- Multi-model comparison — run the same prompt against up to 3 models side by side
- Markdown rendering with syntax-highlighted code blocks, copy button, and line count
- Image/file attachments on messages
- Per-conversation settings (temperature, max tokens, system prompt) via a real, functional settings sheet
- Auto-generated conversation titles, pinning, and full-text search across chat history
- Real per-message token counting and cost estimation, rolled up into a live Usage & Costs dashboard

### Image Generation
- DALL·E 3/2 (OpenAI), Stable Diffusion 3 (Stability AI), Flux 1.1 Pro (Replicate)
- Aspect ratio selector, style presets, negative prompts, batch generation
- History and favorites gallery
- Local notification when a generation finishes (respects the Notifications setting)

### Voice AI
- Speech-to-text via Whisper, text-to-speech via OpenAI (6 voices) and ElevenLabs (with voice cloning)
- Full record → transcribe → chat → synthesize → play pipeline

### Code AI
- Multi-tab code editor with a JetBrains Mono dark theme
- Project management with per-language templates
- One-tap AI code review that streams feedback into an output panel

### Terminal
- A real bash-style command interpreter (`ls`, `cd`, `mkdir`, `cat`, `git`, `flutter`, `dart`, `node`, `python`) with command history and quick-command chips

### AI Agents
- Built-in agents (Research Assistant, Code Reviewer, Creative Writer, Data Analyst) plus a builder for custom ones
- A real ReAct (Reason + Act) loop with tool execution, not a scripted demo
- MCP (Model Context Protocol) server integration for external tool access
- Visual workflow builder for chaining multiple agent steps
- Local notification when an agent run completes

### Document AI
- Upload PDF/TXT/MD/CSV/JSON, then summarize, extract key points, deep-analyze, or ask direct questions answered only from the document's contents

### Search AI
- Web search with AI-generated summaries, plus a Deep Research mode that runs multiple sub-queries and synthesizes a full report

### Local Models (Ollama / LM Studio)
- Connect to a locally-running Ollama instance over your LAN or via `adb forward`
- Model discovery, pull-with-progress, and delete, all from the app

### Security & Privacy
- API keys are encrypted with AES-256-GCM and stored in the platform secure keystore, never in plain text
- Optional biometric app lock that actually re-locks the app whenever it leaves the foreground
- No ads, no third-party analytics SDK bundled in

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/        # App, API, and provider constants
│   ├── di/                # Riverpod dependency injection container
│   ├── error/             # Typed exceptions and failures
│   ├── network/           # Dio client + custom SSE parsers (OpenAI-style and Anthropic-style)
│   ├── router/             # GoRouter config
│   ├── security/           # AES-256-GCM encryption, biometric auth
│   ├── services/           # Cross-cutting services (local notifications)
│   ├── storage/            # SecureStorage (keys), SharedPrefs (settings), Hive (data)
│   ├── theme/               # Material 3 theme, dark-first color system
│   └── utils/               # Extensions
├── data/
│   ├── datasources/
│   │   ├── remote/         # One client per AI provider (streaming + REST)
│   │   └── local/           # Hive-backed conversation datasource
│   ├── models/              # Hive models with hand-written adapters (no build_runner needed)
│   ├── repositories/        # Chat, provider, image, voice repositories
│   └── services/            # AI router, token counter, cost tracker, health monitor, MCP client
└── features/                # One folder per feature area (chat, agent_ai, image_gen, code_ai, …),
                              # each with presentation/screens, presentation/widgets, and providers
```

**State management:** Riverpod (`StateNotifierProvider`, `FutureProvider`, plain `Provider`)
**Navigation:** GoRouter with a `StatefulShellRoute` for the 5-tab bottom nav
**Persistence:** Hive for structured data, `flutter_secure_storage` for API keys, `SharedPreferences` for settings
**Networking:** Dio with hand-rolled SSE parsing for every provider's streaming format

---

## ⚡ Quick Start

### Prerequisites
- Flutter 3.24+ / Dart 3.3+
- Android SDK 26+ (Android 8.0), target/compile SDK 34
- JDK 17
- NDK 27.0.12077973

### Setup

```bash
git clone https://github.com/mkgaming000/Mk_AI.git
cd Mk_AI
flutter pub get
```

Edit `android/local.properties` and point `sdk.dir` / `flutter.sdk` at your local installations (this file is gitignored on purpose — everyone's paths differ).

```bash
flutter run --release
```

> **Note on `gradle-wrapper.jar`:** this binary could not be generated in the sandboxed environment this project was built in (no network access, no local Gradle install available to bootstrap it from). `gradle-wrapper.properties` is present and correct, so:
> - **Android Studio** will download the wrapper jar automatically on first project sync — no action needed.
> - **Command line only:** run `gradle wrapper --gradle-version 8.7` once (with any locally installed Gradle) from the `android/` directory to generate it.
> - **CI:** `.github/workflows/build.yml` bootstraps it automatically before building.

### Add API Keys
Launch the app → **Settings → API Keys** → tap any provider to add its key. Keys are encrypted with AES-256-GCM and stored in the Android Keystore — never in plain text, never leaves the device.

### Connect Local Models (Ollama)
1. Run Ollama on your computer: `ollama serve`
2. Same Wi-Fi network: use your computer's LAN IP as the server address in **Settings → Local Models**
3. Android emulator instead of a device: use `http://10.0.2.2:11434` (already the default) or `adb forward tcp:11434 tcp:11434` for a physical device over USB

---

## 🔑 Where to get API keys

| Provider | Console |
|---|---|
| OpenAI | platform.openai.com |
| Anthropic | console.anthropic.com |
| Google Gemini | aistudio.google.com |
| xAI Grok | console.x.ai |
| DeepSeek | platform.deepseek.com |
| Mistral | console.mistral.ai |
| OpenRouter | openrouter.ai/keys |
| HuggingFace | huggingface.co/settings/tokens |
| Together AI | api.together.xyz |
| Stability AI | platform.stability.ai |
| Replicate | replicate.com/account/api-tokens |
| ElevenLabs | elevenlabs.io |

---

## 🧪 Tests

```bash
flutter test
```

Covers token estimation/cost calculation, provider health tracking and failover selection, AES-256-GCM encryption round-tripping, and the chat input bar widget.

---

## 📁 License

MIT — see `LICENSE`.
