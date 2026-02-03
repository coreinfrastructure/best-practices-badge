# Translations

This document describes how translations are managed for the
OpenSSF Best Practices Badge application.

## Overview

The application supports multiple languages. English (`en`) is the source
language, with translations available for (sorted in English alphabetic order):

- Chinese Simplified (`zh-CN`)
- French (`fr`)
- German (`de`)
- Japanese (`ja`)
- Portuguese Brazilian (`pt-BR`)
- Russian (`ru`)
- Spanish (`es`)
- Swahili (`sw`)

Other natural languages can be added.

Translations come from two sources:

1. **Human translations** - Primary source, provided via translation.io
2. **Machine translations** - Fill gaps where human translations don't exist

Current human translations always take precedence over machine translations.

## Human Translations

Human translations are managed through [translation.io](https://translation.io).
Translators use the translation.io web interface to provide translations.

**Files:**

- `config/locales/en.yml` - English source text
- `config/locales/translation.*.yml` - Human translations from translation.io

**Syncing translations:**

```bash
rake translation:sync
```

This sends updated English text to translation.io and retrieves
any new human translations.

## Machine Translations

Machine translations provide fallback text when human translations
aren't available. They're stored separately and automatically
overridden when humans provide translations.

**Files:**

- `config/machine_translations/*.yml` - Machine-translated text

### How Precedence Works

Rails I18n loads translation files in order, with later files overriding
earlier ones. Machine translations are loaded first, then human translations,
so human translations always win:

1. Load `config/machine_translations/*.yml` (machine translations)
2. Load `config/locales/*.yml` (human translations override)

### Rake Tasks

#### Show translation status

```bash
rake translation:status
```

Shows how many keys have human translations, machine translations,
or are missing for each locale.

#### Export keys for translation

```bash
rake translation:export[LOCALE,COUNT]
```

Exports untranslated keys to a YAML file for translation.

Examples:

```bash
rake translation:export[fr,50]      # Export 50 French keys
rake translation:export[de,100]     # Export 100 German keys
rake translation:export             # Export 50 keys for next priority locale
```

The exported file is saved to `tmp/translate_to_LOCALE_TIMESTAMP.yml`.

#### Import translated file

```bash
rake translation:import[LOCALE,FILE]
```

Imports a translated YAML file into machine translations.

Example:

```bash
rake translation:import[fr,tmp/translate_to_fr_20240101_120000.yml]
```

#### Clean up machine translations

```bash
rake translation:cleanup
```

Removes machine translations for keys that now have human translations.
Run this periodically after `rake translation:sync`.

#### List untranslated keys

```bash
rake translation:untranslated[LOCALE]
```

Lists keys that need translation for a specific locale.

### Translation Workflow

1. **Export** keys needing translation:

   ```bash
   rake translation:export[fr,50]
   ```

2. **Translate** the exported YAML file using any tool:
   - GitHub Copilot
   - ChatGPT or other LLMs
   - Human translator
   - Any translation service

3. **Review** the translations for accuracy

4. **Import** the translated file:

   ```bash
   rake translation:import[fr,tmp/translate_to_fr_20240101_120000.yml]
   ```

5. **Commit** the updated machine translation files

### Translation Guidelines

When translating:

- Only translate VALUES, never the keys
- Keep template variables like `%{name}` unchanged
- Keep HTML tags like `<a href="...">` unchanged
- Change `/en/` paths to the target locale (e.g., `/fr/`)
- Preserve YAML formatting and indentation

### Priority Order

Machine translations are processed in this priority order:

1. French (fr) - reviewer can verify to a limited extent
2. German (de) - reviewer can verify to a very limited extent
3. Japanese (ja)
4. Chinese Simplified (zh-CN)
5. Portuguese Brazilian (pt-BR)
6. Spanish (es)
7. Russian (ru)
8. Swahili (sw) - lowest priority, limited LLM support

## Automatically translating

Run `translation:copilot` to automatically call GitHub pilot to
perform translations of what needs translating and add them.
When run, copilot only has read/write access to a `tmp` directory.

The plan is to repeatedly run this as a cron job to slowly fill in
translations *without* significantly burdening the AI system.

## Adding a New Language

To add support for a new language:

1. Add the locale to `config/initializers/i18n.rb`
2. Create `config/locales/localization.LOCALE.yml` with locale-specific
   settings (date formats, etc.)
3. Add the locale to translation.io
4. Run `rake translation:sync`
5. Optionally create machine translations to fill gaps
