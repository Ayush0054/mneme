# Mneme · μνήμη

**Your clipboard, kept in order.**

A native macOS menu-bar clipboard with an ordered paste queue and optional AI matching for the field you're filling.

![Mneme's dark glass clipboard panel](docs/images/mneme.png)
<sub>Presentation image polished from an app screenshot.</sub>

## Features

- **Copy in order, paste in order.** Queue up to 100 text items, rearrange them, and restore the last sent item.
- **Search your history.** Keep the latest 200 copies; optionally remember history between launches.
- **Smart Paste.** TypeSafe's Jev selects the copied item that fits the focused field. Review suggestions, or opt into automatic pasting of strong matches.
- **Made for Mac.** Configurable global shortcuts, a native menu-bar icon, and a paper-and-glass interface with Instrument Serif and DM Sans.
- **Local by default.** Capture pause, app exclusions, and best-effort filtering for concealed clipboard content and recognizable secrets.

## Get started

Requires **macOS 14+** and **Xcode Command Line Tools / Swift 5.9+**. Smart Paste also needs [uv](https://docs.astral.sh/uv/getting-started/installation/) and a TypeSafe API key.

```sh
git clone https://github.com/Ayush0054/mneme.git
cd mneme
bash scripts/package-app.sh
open dist/Mneme.app
```

Grant **Mneme.app** access in **System Settings → Privacy & Security → Accessibility** to paste into other apps. Quit Mneme before rebuilding; a rebuild may require re-adding its Accessibility permission.

For optional Smart Paste:

```sh
bash scripts/setup.sh
cp .env.example .env   # first-time setup only
```

Set `TYPESAFE_API_KEY` in `.env`, then enable **TypeSafe Smart Paste** in Mneme's Settings. You can instead save the key in Settings using macOS Keychain. A nonempty `.env` key takes precedence; `.env` is ignored by Git and never bundled.

## Use it

| Action | Default shortcut |
| --- | --- |
| Smart Paste | `⌥V` |
| Paste next | `⇧⌥V` |
| Open / close panel | `⌥Space` |

Leave **Collect copies** on, copy several values, focus a destination field, and use **Paste next**. Move between fields yourself. Ordinary `⌘V` is unchanged. Change shortcut presets in Settings.

**Smart Paste:** copy a contact block once. Click **Full name** and press `⌥V` to paste the name; click **Work email** and press `⌥V` to paste the email; repeat for **Company**. The original copy stays available. Clear matches paste directly, without opening the panel. A small spinner follows the pointer while Mneme matches and pastes; it disappears on completion, error, or cancellation. Uncertain matches and errors leave the field untouched and play an error sound; open Mneme manually to read the status.

## Try the demo

The [demo form](demo/index.html) contains a fictional contact and three labeled fields. With Mneme running and Smart Paste enabled, copy the contact once, focus each field, and press `⌥V`.

Serve it from the repository root:

```sh
python3 -m http.server 8766 --bind 127.0.0.1
```

Open [localhost:8766/demo/](http://localhost:8766/demo/). This server only serves the demo page; Mneme starts its own Python helper when needed.

## What TypeSafe / Jev does

Mneme locally finds exact values in the newest 12 copies: labeled lines such as `Name: Ada Lovelace`, email addresses, phone-like numbers, links, and individual lines. It considers the first 1,200 characters of each source, excludes incomplete trailing spans, and offers up to 60 distinct candidates. Single-line fields cannot receive multiline blocks.

[TypeSafe's Python SDK](https://docs.typesafe.ai/sdk/python) with `jev-1.13.0` classifies which candidate belongs in the focused field using its label, placeholder, and help text. Jev returns a candidate ID or **none**; it does not generate replacement text or control your Mac. Mneme rechecks the focused destination and pastes only the selected value. Strong matches require confidence ≥ 0.85, probability ≥ 0.90, and a ≥ 0.25 lead over alternatives; these thresholds are provisional.

There is no separate extraction button or confirmation step. Mneme does not navigate or submit forms: focus each field and invoke the shortcut. Unstructured paragraphs or values not found by local parsing may produce no match.

## Current limits

This is an early development version: **plain text only**, with no image/file history, sync, OCR, or automatic form navigation. A sent paste keystroke does not guarantee the destination accepted it; use **Return last sent item to queue** if needed.

Capture and ordered paste stay local. Only explicit Smart Paste requests use the cloud. History stays in memory by default; optional saved history is local and **unencrypted**. Secret filtering is not comprehensive.

Build locally: there is no notarized download yet. Keep the project folder in place—the packaged app locates `.env` and the Python helper there. Repackage after moving the folder. Fonts and their SIL Open Font Licenses are in [Resources/Fonts](Resources/Fonts).

## License

[MIT](LICENSE) © 2026 Ayush Jha. Bundled fonts retain their SIL Open Font Licenses.
