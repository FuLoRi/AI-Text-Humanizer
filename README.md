# AI Text Humanizer

A Windows PowerShell GUI tool that cleans AI-generated text by replacing or removing Unicode characters that humans rarely type, and optionally strips Markdown formatting and emoji. It also includes a heuristic detector that scores how likely a piece of text is to have been written by an AI.

## Features

- **Detect AI** — scores the input text for AI likelihood based on Unicode signals, phrase patterns, and structure
- **Humanize** — replaces or removes AI-telltale characters and outputs clean, human-looking text
- **Remove Markdown** (optional) — strips headers, bold, italic, code blocks, links, and blockquotes while preserving the underlying text
- **Remove Emoji** (optional) — strips emoji from BMP and supplementary Unicode planes
- **Copy Output** — puts the humanized text straight onto the clipboard
- **Change summary** — the status bar reports exactly what was changed (e.g. `Em dashes (-): 5 | Curly double quotes: 8`)

## What gets replaced

### Always (core humanization)

| AI character | Replaced with |
|---|---|
| Em dash `—` (U+2014), horizontal bar `―` (U+2015) | `-` |
| En dash `–` (U+2013), figure dash `‒` (U+2012), minus sign `−` (U+2212) | `-` |
| Curly double quotes `"` `"` and guillemets `«` `»` | `"` |
| Curly single quotes `'` `'` and angle quotes `‹` `›` | `'` |
| Ellipsis `…` (U+2026) | `...` |
| Bullet `•` and variants (`‣`, `◦`, `⁃`, `∙`) | `-` |
| Decorative arrows `→` `➔` `➤` `▸` `▹` `►` | `->` or `-` |
| Zero-width space, non-joiner, joiner, word joiner, BOM, soft hyphen, LTR/RTL marks | *(removed)* |
| Non-breaking space, thin space, hair space, figure space, narrow no-break space, em/en space, etc. | ` ` (regular space) |

### When "Remove Markdown" is checked

Strips `#` headers, `**bold**`, `*italic*`, `~~strikethrough~~`, `` `inline code` ``, code fences, `[links](url)` (keeps text + URL), `> blockquotes`, and `---` horizontal rules.

### When "Remove Emoji" is checked

Removes emoji across all Unicode planes, including supplementary plane emoji (encoded as surrogate pairs in .NET), flag sequences, skin tone modifiers, and variation selectors.

## AI Detection

The **Detect AI** button analyzes the input text without modifying it and displays a scored result in the status bar:

```
AI likelihood: HIGH (score 88/100) -- em dash x3 | curly quotes x8 | AI phrases: "delve", "furthermore", "nuanced"
```

### Signals checked

**Unicode telltales** — em dashes, curly quotes, ellipsis characters, zero-width spaces, non-breaking spaces (each weighted by frequency)

**AI phrases** — roughly 30 patterns including:
- `delve`, `nuanced`, `multifaceted`, `pivotal`, `crucial`, `robust`, `seamlessly`, `tapestry`, `landscape`, `paradigm`
- `it's worth noting`, `it is important to note`, `please note that`, `feel free to`
- `furthermore`, `moreover`, `additionally`, `nevertheless`
- `in conclusion`, `in summary`, `to summarize`
- `as an AI`, `I cannot`, `I'm unable to`, `I'd be happy to`, `great question`
- `certainly!`, `absolutely!`, `at the end of the day`

**Structural patterns** — transition words opening sentences, abnormally uniform sentence length (low coefficient of variation)

**Markdown in plain text** — `##` headers and `**bold**` in what should be plain prose

### Confidence levels

| Score | Label |
|---|---|
| 0–9 | UNLIKELY |
| 10–29 | LOW |
| 30–59 | MEDIUM |
| 60–100 | HIGH |

> The detector is heuristic-based, not ML-based. It will miss subtle AI writing and may flag human text that happens to use formal language. Use it as a quick sanity check, not a definitive verdict.

## Requirements

- Windows 10 or later
- PowerShell 5.1 or later (included with Windows 10+)
- No external modules or dependencies

## Installation

### Quick Install (Recommended)

1. Download the latest `.zip` from [Releases](https://github.com/FuLoRi/AI-Text-Humanizer/releases/latest)
2. Extract the zip to any folder
3. Double-click **Install.bat**
4. Choose where to place shortcuts (Desktop and/or Start Menu)
5. Launch from your new shortcut

The installer copies files to `%LOCALAPPDATA%\AI-Text-Humanizer` and creates shortcuts that handle execution policy automatically. No console window appears when launching from the shortcut.

### Manual Run (No Install)

If you prefer not to install, download `AI-Text-Humanizer.ps1` and run it directly:

```powershell
powershell -ExecutionPolicy Bypass -File "AI-Text-Humanizer.ps1"
```

### Uninstall

Run `Uninstall.ps1` from the install directory (`%LOCALAPPDATA%\AI-Text-Humanizer`), or simply delete that folder and remove any shortcuts you created.

## Usage

1. Copy text from ChatGPT, Claude, or any AI tool
2. Paste into the top input field (`Ctrl+V`)
3. Optionally click **Detect AI** to see a likelihood score before cleaning
4. Check **Remove Markdown** and/or **Remove Emoji** if needed
5. Click **Humanize**
6. Review the output in the bottom field
7. Click **Copy Output** (or `Ctrl+A` then `Ctrl+C` in the output field)
8. Paste into your email, document, or wherever you need it

## License

GPL-3.0
