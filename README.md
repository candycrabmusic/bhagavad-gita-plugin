# Bhagavad Gita — Omarchy Plugin

Read the Bhagavad Gita from your Omarchy status bar. A bar widget that opens a keyboard-navigable scripture browser.

- **Plugin ID:** `vishakh.bhagavad-gita`
- **Kind:** bar-widget
- **License:** MIT

## Features

- Daily verse shown by default when the panel opens
- Browse all 700 verses across 18 chapters
- Previous / Next navigation with chapter boundary handling
- Random verse
- Search across Sanskrit, transliteration, and translation
- Configurable display (Sanskrit / transliteration / translation toggles)
- Keyboard-driven, fully local — no network calls

## Installation

Install from the marketplace (once published):

```bash
omarchy plugin install vishakh.bhagavad-gita
```

### Manual install

Clone or download this repository into your plugins directory:

```bash
mkdir -p ~/.config/omarchy/plugins
git clone https://github.com/<owner>/vishakh.bhagavad-gita ~/.config/omarchy/plugins/vishakh.bhagavad-gita
```

### Enable the widget

Add the widget to your bar layout in `~/.config/omarchy/shell.json`:

```json
{
  "bar": {
    "layout": {
      "center": [
        { "id": "vishakh.bhagavad-gita" }
      ]
    }
  }
}
```

Then rescan plugins:

```bash
omarchy-shell shell rescanPlugins
```

### Uninstall / removal

Remove the plugin directory (and any widget entry from your bar layout):

```bash
rm -rf ~/.config/omarchy/plugins/vishakh.bhagavad-gita
```

## Validation

```bash
omarchy plugin validate ~/.config/omarchy/plugins/vishakh.bhagavad-gita
```

## Data source

Verses use the public-domain Swami Sivananda translation (Divine Life Society,
1930s), IAST transliteration, and Devanagari Sanskrit text.

## License

MIT. See [LICENSE](LICENSE).
