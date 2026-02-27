# Updating the Baseline Criteria

This document explains the steps to update the
[OpenSSF Open Source Project Security Baseline (OSPS Baseline)](https://baseline.openssf.org/)
criteria when a new version is published.

The baseline criteria are stored in `criteria/baseline_criteria.yml`.
When a new version is published, existing criteria may have updated text, and
new criteria may be added.

When we import the updated baseline criteria,
updated criteria text with an existing identifier is used immediately
(these are clarifications and/or minor relaxations).
New criteria are initially marked `future: true`
so they are visible in the form (with an "upcoming criterion" label) but do
not count toward the badge percentage until the transition period ends.

## Step 0: Verify No Current "Future" Criteria

Before starting an update, confirm that no criteria in the current file are
marked as future. This ensures you are beginning from a stable, fully-active
baseline before introducing new criteria.

```bash
grep -c 'future: true' criteria/baseline_criteria.yml
```

This should print `0`. If it prints a non-zero number, the previous update
cycle is not yet complete—existing future criteria have not yet been
activated. Resolve that first (see
[Removing the "Future" Marking](#removing-the-future-marking) below).

You can also run the validator to confirm the file is internally consistent:

```bash
rake baseline:validate
```

## Step 1: Identify the New Baseline Version

Visit <https://baseline.openssf.org/> to find the URL of the new version.
Version URLs follow the format
`https://baseline.openssf.org/versions/YYYY-MM-DD`.

Record both the old and new version strings. For example:

- Old version: `2025-10-10` (currently in `criteria/baseline_criteria.yml`
  under `_metadata.source_url` and in `config/baseline_config.yml`)
- New version: `2026-02-19` (replace with the actual new date)

## Step 2: Download the Updated Baseline Criteria HTML

Create the `tmp/` directory if it does not exist, then download the new
version's HTML page:

```bash
mkdir -p tmp
curl -s 'https://baseline.openssf.org/versions/YYYY-MM-DD' \
     -o tmp/baseline_source.html
```

Replace `YYYY-MM-DD` with the new version date (e.g., `2026-02-19`).

## Step 3: Parse and Extract the Criteria

Run the extraction script to parse the downloaded HTML and produce working
files in `tmp/`:

```bash
script/extract_baseline.rb
```

**Inputs:**

- `tmp/baseline_source.html` — the downloaded HTML from Step 2
- `criteria/baseline_criteria.yml` — the current criteria file, used to
  detect new, obsolete, and changed criteria and to preserve `future:` and
  `obsolete:` flags on re-extraction

**Outputs (in `tmp/`, not yet committed):**

- `tmp/baseline_extracted.yml` — criteria in the application's YAML format,
  with `future: true` automatically added to any criterion whose key does not
  yet exist in `criteria/baseline_criteria.yml`, and `obsolete: true`
  re-added to any existing criterion whose key is absent from the new version
- `tmp/baseline_extracted.json` — same data in JSON (useful for review)

It prints a summary showing how many controls were extracted, how they are
distributed across maturity levels and categories, and which (if any) keys
are new, obsolete, or had their description/details text changed.
Verify the counts look reasonable compared with the previous version.

**Re-running is safe.** Given the same inputs the script always produces the
same outputs—`future:` and `obsolete:` flags already present in
`criteria/baseline_criteria.yml` are preserved in the extracted file.
No data is lost by re-running.

## Step 4: Review and Merge Changes into baseline_criteria.yml

Copy the extracted file over the current criteria file and use `git diff`
to review what changed:

```bash
cp tmp/baseline_extracted.yml criteria/baseline_criteria.yml
git diff criteria/baseline_criteria.yml
```

The extraction script already annotates the two interesting cases
automatically and reports them on stdout:

- **New criteria** (not in the previous file): marked `future: true`
- **Obsolete criteria** (in the previous file but absent from the new
  upstream version): re-added at their original location with `obsolete: true`

Review the script's output to confirm these lists look reasonable. If the
number of obsolete criteria is unexpectedly large it likely indicates a
**failed or partial import** (e.g., the HTML parser missed a section).
In that case, stop, investigate `tmp/baseline_extracted.yml`, and re-run
Step 3 before continuing.

Obsolete criteria are shown on the baseline form with an "(Obsolete criterion)"
label so users can refer to them while updating their other answers. They are
excluded from badge percentage calculations. Do not drop the corresponding
database columns for obsolete criteria; retained columns cause no harm and
preserve historical data.

Also update the `_metadata` section at the top of
`criteria/baseline_criteria.yml` to reflect the new version:

```yaml
_metadata:
  source: OpenSSF Baseline HTML
  source_url: https://baseline.openssf.org/versions/YYYY-MM-DD
  extracted_at: 'YYYY-MM-DDTHH:MM:SS-ZZ:ZZ'
  auto_generated: true
  total_controls: NN
```

## Step 5: Generate and Run a Database Migration (New Criteria Only)

If any new criteria were added in Step 4, their `_status` and
`_justification` columns do not yet exist in the database. Generate the
migration:

```bash
rake baseline:generate_migration
```

**Inputs:**

- `criteria/baseline_criteria.yml` — source of truth for which criteria keys
  must exist
- `config/baseline_field_mapping.json` — maps criterion keys to database
  column names (created automatically if absent)

**Outputs:**

- `config/baseline_field_mapping.json` — updated with any new criteria keys
  not yet present in the file
- `db/migrate/TIMESTAMP_add_baseline_criteria_*.rb` — a new migration adding
  the `_status` and `_justification` columns for each new criterion

Be sure to `git add` both the updated mapping file and the new migration.

**Re-running:** If you re-run the task with no new criteria, it reports
"No new fields to add" and writes no migration. If there are new criteria
but you already ran the task, a second run will again find nothing to add
(the mapping file was already updated). Running the migration itself
(`rails db:migrate`) is always safe to re-run; Rails skips already-applied
migrations.

Apply the migration:

```bash
rails db:migrate
```

If no new criteria were added, skip this step (running
`rake baseline:generate_migration` will report "No new fields to add").

## Step 6: Update the i18n Translations

Extract the updated `description`, `details`, and placeholder text from
`criteria/baseline_criteria.yml` into `config/locales/en.yml`:

```bash
rake baseline:extract_i18n
```

**Inputs:** `criteria/baseline_criteria.yml`

**Output:** `config/locales/en.yml` — the section between markers
`# BEGIN BASELINE CRITERIA AUTO-GENERATED` and
`# END BASELINE CRITERIA AUTO-GENERATED` is replaced with the current
criteria text. All content outside those markers is preserved unchanged.

The extraction includes **all** criteria regardless of their `future:` or
`obsolete:` status, so text for upcoming and retired criteria is available
in the locale file for display on the form.

**Re-running is safe and idempotent.** Re-run it whenever you modify
`criteria/baseline_criteria.yml` to keep the locale file in sync.

## Step 7: Validate the Updated Criteria

Run the validator to confirm the files are internally consistent:

```bash
rake baseline:validate
```

**Inputs (read-only, nothing is written):**

- `criteria/baseline_criteria.yml`
- `config/locales/en.yml`
- `config/baseline_field_mapping.json` (if present)

**What it checks:**

- `criteria/baseline_criteria.yml` is valid YAML
- No criterion has both `future: true` and `obsolete: true` simultaneously
- Every criterion has a non-empty `description`
- Every criterion whose description is in the criteria YAML is also present
  in `config/locales/en.yml` (detects a missing `rake baseline:extract_i18n`
  run)
- `config/baseline_field_mapping.json` is valid JSON (if the file exists)

A passing run prints:

```
✓ Baseline criteria validation passed
```

Fix any reported errors before continuing.

## Step 8: Update the Version Notice Partial

Edit `app/views/projects/_form_baseline_version_notice.html.erb` to
reflect the transition. During the transition period (after the new criteria
are deployed but before they are enforced), set `baseline_in_transition` to
`true` and fill in all three version variables:

```erb
<%
  baseline_in_transition   = true
  baseline_current_version = 'v2025.10.10'
  baseline_new_version     = 'v2026.02.19'
  baseline_enforce_date    = '2026-04-01'
%>
```

- `baseline_current_version` is the version whose criteria are currently
  active (the old version, until the enforce date).
- `baseline_new_version` is the version being adopted (criteria shown as
  "upcoming").
- `baseline_enforce_date` is the date (YYYY-MM-DD) when new criteria start
  counting toward the badge.

When not in transition (steady state), set `baseline_in_transition = false`
and update `baseline_current_version` to the new version string:

```erb
<%
  baseline_in_transition   = false
  baseline_current_version = 'v2026.02.19'
  baseline_new_version     = ''
  baseline_enforce_date    = ''
%>
```

The `baseline_new_version` and `baseline_enforce_date` variables are
ignored when `baseline_in_transition` is `false`.

## Step 9: Restart the Application

Criteria are loaded into `CriteriaHash` and `FullCriteriaHash` at Rails
startup in `config/initializers/00_criteria_hash.rb`. Changes to
`criteria/baseline_criteria.yml` or `config/locales/en.yml` do not take
effect until the application is restarted.

In development:

```bash
rails s
```

In production, follow the standard deployment procedure (e.g., restart
Puma workers).

## Step 10: Verify a Changed Criterion Shows the Updated Text

Open a project's baseline form (e.g., `/en/projects/1/baseline-1`) and
navigate to a criterion whose text was updated in Step 4. Confirm that the
form now displays the new description and details text.

Alternatively, check from the Rails console:

```ruby
Criteria['baseline-1']['osps_xx_nn_nn'].description
```

Replace `osps_xx_nn_nn` with the key of the changed criterion.

## Step 11: Verify a New Criterion Is Served but Marked "Future"

Open the same baseline form and locate the new criterion. It should be
visible with the label "(upcoming criterion)" before its description. This
label is rendered by `app/views/projects/_status_chooser.html.erb` when
`criterion.future?` returns `true`.

Confirm from the Rails console that the criterion exists but is excluded
from the active set:

```ruby
# Should exist:
Criteria['baseline-1']['osps_xx_nn_nn']

# Should NOT appear in the active list:
Criteria.active('baseline-1').map(&:name).include?('osps_xx_nn_nn')
# => false
```

Replace `osps_xx_nn_nn` with the new criterion's key.

## Step 12: Perform Machine Translation

After `config/locales/en.yml` has been updated with the new and changed
criterion text, run automated machine translation to fill in the other
supported locales:

```bash
rake translation:all
```

This iterates over all locales that have untranslated or stale segments
(i.e., where the English source has changed since the machine translation
was generated) and translates them using GitHub Copilot. It runs until all
locales are up to date. Human translations always take precedence over
machine translations.

You can check translation status before and after with:

```bash
rake translation:status
```

## Removing the "Future" Marking

When the enforce date arrives (the date set in `baseline_enforce_date`),
the criteria that were previously marked `future: true` should become fully
active. To activate them:

1. Remove `future: true` from each affected criterion in
   `criteria/baseline_criteria.yml`. If `future: false` was set explicitly,
   remove that line too (the default is `false`).

2. Run `rake baseline:extract_i18n` to sync any text changes that may have
   occurred since the criteria were first added.

3. Run `rake baseline:validate` to confirm the file is still valid.

4. Update `app/views/projects/_form_baseline_version_notice.html.erb`:
   set `baseline_in_transition = false` and update
   `baseline_current_version` to the now-active version string (see
   Step 8).

5. Restart the application. The newly activated criteria will be included
   in `Criteria.active(level)` and will count toward badge percentages.

6. Verify by checking the Rails console:

   ```ruby
   Criteria.active('baseline-1').map(&:name).include?('osps_xx_nn_nn')
   # => true
   ```

## Removing display of obsolete criteria

If there were obsolete criteria, eventually you probably should remove
them from display.
