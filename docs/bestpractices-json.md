# Add support for .bestpractices.json declaration

## Overview

Projects can self-declare project values (such as criterion status
and criterion justification) by placing a
`.bestpractices.json` file in their repository. This allows projects to
provide automation hints that will auto-fill criterion fields during badge
application.

## File Location

The system checks for the file in two locations (in order):

1. `.bestpractices.json` (repository root)
2. `.project.d/bestpractices.json` (fallback location)

## File Format

The file must be valid JSON with UTF-8 encoding. Maximum file size: 50 KB.

### Example

```json
{
  "contribution_status": "Met",
  "contribution_justification": "See CONTRIBUTING.md for details",
  "license_location_status": "Met",
  "license_location_justification": "License in LICENSE file at repo root",
  "build_status": "Met",
  "build_justification": "We use Maven - see pom.xml"
}
```

### Field Names

- Use exact criterion field names (e.g., `contribution_status`,
  `license_location_status`)
- Field names are case-sensitive, they must be in lower case.
- Field names don't have `.` or `-` (use `_` instead)
- Only valid criterion fields are accepted (invalid fields are ignored)

### Criterion Status Values

- Must be **text strings**: `"Met"`, `"Unmet"`, `"N/A"`
- Case-insensitive: `"met"`, `"Met"`, `"MET"` all work
- **Do NOT use** question marks (`"?"`) or empty strings - these are ignored
- **Do NOT use** numbers like `3` or `1` - those are internal representations

### Criterion Justification Fields

- Optional but recommended with status fields
- Field names end with `_justification` (e.g., `contribution_justification`)
- Maximum length: 8192 characters
- Must be valid UTF-8 text
- Empty justifications are ignored

## How It Works

### Confidence Level

Self-declared values have **confidence level 3.5**, which means:

- They will **fill in blank fields** (criterion with status `?` and
  empty non-criteria)
- They will **NOT override** existing values in the badgeapp
- They appear as **automation suggestions** (yellow highlight in UI)
- Users can accept, reject, or modify these suggestions

### Section Filtering

The system applies normal section filtering:

- Values are only proposed for the section you're currently editing
- This prevents surprising changes in sections you're not viewing
- The same JSON file can serve all badge levels (passing, silver, gold,
  baseline-1, baseline-2, and baseline-3)

### Justification Handling

- If a status field has a corresponding justification in the JSON, that text
  is used as the explanation
- If no justification is provided, a generic message is used:
  "Value from project's .bestpractices.json file"

## Creating Your File

### Option 1: Manual Creation

Create the JSON file manually using the format above. Valid field names can
be found in the badge application form.

### Option 2: Export From Badge Site

If you already have a badge entry, you can export it as JSON:

1. Visit your project page: `https://www.bestpractices.dev/projects/YOUR_ID`
2. Add `.json` to the URL: `https://www.bestpractices.dev/projects/YOUR_ID.json`
3. Save the JSON response
4. Extract the relevant `_status` and `_justification` fields
5. Place in `.bestpractices.json` in your repository

## Validation Rules

### What Gets Ignored

The following are silently ignored (no errors shown):

- JSON with invalid JSON syntax or not in UTF-8 encoding
- Files larger than 50 KB
- Invalid field names
- Status value of `"?"` (and its justification)
- Empty status or justification values
- Invalid status values (not in allowed set)
- Text exceeding maximum length

### Error Handling

- Invalid files never cause errors in the badge application
- The system gracefully falls back to other automation detectives
- Validation errors are logged at INFO level for project maintainer debugging

## Use Cases

### 1. Pre-filling New Badge Applications

When creating a new badge application, the JSON file will automatically
suggest answers for criteria that might not be auto-detected.

### 2. Overriding Heuristic Detection

If automated detection gets something wrong, you can provide the correct
value via JSON (though you can also just edit the field directly).

### 3. Documenting Unusual Situations

For projects with non-standard structures, the JSON file can explain why
certain criteria are met despite not matching typical patterns.

## Security

- File size limits prevent DoS attacks
- JSON parsing is safe (no code execution)
- Field validation prevents injection attacks
- UTF-8 encoding is strictly enforced
- Only known criterion fields are accepted

## Technical Details

### Implementation

The feature is implemented via the detective pattern:

- **CriterionFieldValidator**: Reusable validation module
- **RepoJsonDetective**: Reads and validates the JSON file
- **GithubContentAccess**: Enhanced to fetch file content

### Currently Supported

- GitHub repositories (via GitHub Contents API)
- Future: GitLab, Gitea, and other platforms

## Troubleshooting

### My JSON file isn't being detected

1. Check file location: `.bestpractices.json` or `.project.d/bestpractices.json`
2. Verify JSON syntax with a validator (e.g., `python -m json.tool < .bestpractices.json`)
3. Ensure UTF-8 encoding
4. Check field names match exactly (case-sensitive)
5. Verify file size < 50 KB

### Values aren't being applied

1. Check status values are strings (`"Met"` not `3`)
2. Don't use `"?"` or empty strings as status values
3. Section filtering applies - you'll only see values for the current section

### How to update values

If you've already filled in a field, the JSON file won't override it.
To use new JSON values:

1. Clear the field (set the criterion to `?`, or non-criterion to blank)
2. Trigger re-autofill: edit, then click on "save and continue".
3. The JSON value will then be suggested (you can then edit it further)

## See Also

- [API Documentation](docs/api.md)
