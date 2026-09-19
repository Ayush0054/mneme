# Mneme

- Do not run tests, builds, linters, previews, or runtime checks until the user explicitly asks.
- Keep clipboard capture and ordinary ordered paste local. Only explicit Smart Paste requests may call TypeSafe.
- Never log clipboard text, field context, or API keys.
- Support the user's project-local .env for TYPESAFE_API_KEY, with Keychain as a fallback. Never commit credentials or bundle .env into the app.
- Launch the packaged .app for Accessibility permission flows, not a bare SwiftPM executable.
