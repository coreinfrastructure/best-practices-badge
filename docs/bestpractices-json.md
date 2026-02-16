# Automation Proposals

External automation tools can propose field changes to a project's
badge entry by encoding proposals as query parameters in a project
edit URL. When a user (or tool) visits such a URL, and the user is
authorized to make changes to the project entry, the edit form
displays the proposed values with visual highlighting so the
(authorized) user can review and accept or modify them before saving.

This is not the *only* way an automated tool can retrieve or edit project
badge entry data; we also provide an API to read or change the project
data using JSON. However, the "automation proposals" interface
described here provides a user-friendly way for applications to
propose changes where the authorized human has a chance to review and
approve those changes.

## URL Format

```text
(/:locale)/projects/:id/:section/edit?KEY=VALUE&KEY=VALUE&...
```

Where:

- **`:locale`** is the locale code (e.g., `en`, `fr`).
  The locale is optional and defaults to the user's preferred locale
  if we support it (else English).
- **`:id`** is the numeric project ID.
- **`:section`** is the badge level being edited.
  For the Metal badge series this is `passing`, `silver`, or `gold`.
  For the Baseline badge series this is `baseline-1`, `baseline-2`,
  or `baseline-3`.
- **`KEY=VALUE`** pairs are `&`-separated query parameters, where
  `KEY` is a field name and `VALUE` is the proposed new value.
  Values must be URL-encoded (spaces as `+` or `%20`, etc.).
  The field must be present in the given section, or it's ignored, to
  ensure that humans will have a chance to review the change.

### Examples

Propose a new project description for project 42 when viewing
its passing level section:

```text
/en/projects/42/passing/edit?description=A+secure+widget+library
```

Propose that the `floss_license` criterion is Met in `passing`:

```text
/en/projects/42/passing/edit?floss_license_status=Met
```

Propose multiple fields at once:

```text
/en/projects/42/passing/edit?name=MyProject&floss_license_status=Met&floss_license_justification=MIT+license+in+LICENSE+file
```

Propose a Baseline criterion status:

```text
/en/projects/42/baseline-1/edit?osps_ac_01_01_status=Met&osps_ac_01_01_justification=MFA+enforced+via+GitHub+org+settings
```

## Valid Fields

Each section has a specific set of valid field names.
Proposals for fields that do not belong to the section being edited
are silently ignored.

### Non-criteria Fields (All Sections)

These fields may be proposed in any section:

| Field | Description |
|-------|-------------|
| `name` | Human-readable project name |
| `description` | Short project description |
| `license` | Project license (e.g., `MIT`, `Apache-2.0`) |
| `implementation_languages` | Comma-separated list of languages |

### Criteria Fields

Every criterion has two automatable fields:

- **`CRITERION_status`** - the criterion's status
  (`?`, `N/A`, `Unmet`, or `Met`; see [Status Values](#status-values) below).
- **`CRITERION_justification`** - free-text justification for the status
  (in URL-encoded UTF-8 format).

The criterion name (`CRITERION`) depends on the badge series.

#### Metal Series Criterion Names

Metal series criteria (`passing`, `silver`, `gold`) use short descriptive names.
Examples from the passing level:

| Criterion Name | Description |
|----------------|-------------|
| `description_good` | Project description is clear |
| `floss_license` | Released under a FLOSS license |
| `floss_license_osi` | License is OSI-approved |
| `repo_public` | Public version-controlled repository |
| `contribution` | Contribution process explained |
| `maintained` | Project is actively maintained |
| `version_unique` | Each release has a unique version |
| `static_analysis` | At least one static analysis tool is used |
| `dynamic_analysis` | At least one dynamic analysis tool is used |

The full list of criteria for each level is defined in
`criteria/criteria.yml`.

#### Baseline (OSPS) Criterion Names

Baseline criteria follow a structured naming convention derived from
the [OpenSSF OSPS Baseline](https://baseline.openssf.org/):

```text
osps_CATEGORY_NUMBER_SECTION
```

Where:

- **`CATEGORY`** is a two-letter category code (see table below).
- **`NUMBER`** is a two-digit requirement number (e.g., `01`, `02`).
- **`SECTION`** is a two-digit sub-section number (e.g., `01`, `02`).

Note that OSPS field names are always *lowercase* and never use
dashes or periods (they are replaced with `_`).

**OSPS category codes:**

| Code | Category |
|------|----------|
| `ac` | Access Control |
| `br` | Build & Release |
| `ca` | Change Auditing |
| `cm` | Change Management |
| `do` | Documentation |
| `gv` | Governance |
| `le` | Legal / Licensing |
| `pm` | Project Maintenance |
| `ps` | Project Security |
| `rp` | Reporting |
| `sa` | Security Assessment |
| `ur` | User Relations |

Each OSPS criterion also has an `original_id` in the format
`OSPS-XX-NN.SS` (e.g., `OSPS-AC-01.01`).

**Examples:**

| Field Name | Original ID | Description |
|------------|-------------|-------------|
| `osps_ac_01_01` | OSPS-AC-01.01 | Enforce MFA for repository access |
| `osps_ac_03_01` | OSPS-AC-03.01 | Prevent direct commits to primary branch |
| `osps_br_01_01` | OSPS-BR-01.01 | Use a build system |
| `osps_le_02_01` | OSPS-LE-02.01 | License clearly defined |
| `osps_do_01_01` | OSPS-DO-01.01 | Provide project documentation |

The full list of baseline criteria is defined in
`criteria/baseline_criteria.yml`.

## Status Values

Status fields (`*_status`) accept the following string values
(case-insensitive, whitespace is stripped):

| Value | Meaning |
|-------|---------|
| `?` | Status is unknown (default) |
| `N/A` | Criterion is not applicable |
| `Unmet` | Criterion is not met |
| `Met` | Criterion is met |

Blank or invalid status values are silently rejected;
the field keeps its previous value.

**Note:** Not all criteria allow `N/A`.
The `na_allowed` attribute in the criteria YAML files controls whether
a criterion accepts `N/A` as a valid status.

### Status Value Semantics: Query Strings vs JSON

There's an important distinction between query string proposals and
JSON file automation (see [.bestpractices.json](bestpractices-json.md)):

**Query String Proposals (this mechanism):**

- `?` means **"explicitly reset this field to unknown"**
- Users can clear a previously-set status by passing `?` in the URL
- Example: `...edit?contribution_status=?` resets the status to unknown
- This is intentional - humans can use URLs to reset fields

**JSON File Automation (`.bestpractices.json`):**

- `?` or `"unknown"` means **"I don't know the answer"**
- These values are **ignored entirely** - they provide no automation information
- Example: `{"contribution_status": "?"}` is skipped, existing value unchanged
- This lets you safely reuse JSON files containing placeholder `?` values

**Why the difference?** Query string proposals represent explicit human actions
through a URL. JSON files represent automated tool outputs where `?` means
"no information available" rather than "please clear this field."

This design allows projects to copy `.bestpractices.json` files from templates
or other projects that are filled with `?` placeholders without accidentally
clearing their existing answers.

## Justification Values

Justification fields (`*_justification`) accept any text string.
Blank values are accepted and result in an empty justification.
Values are stripped of leading and trailing whitespace.

## Security and Validation

Automation proposals are validated in several ways:

1. **Field name validation**: Only fields in the pre-computed
   `FIELDS_BY_SECTION` set for the current section are accepted.
   Unknown field names, fields from other sections, and
   non-field query parameters (e.g., `locale`, `utf8`) are silently
   ignored.

2. **Status value validation**: Status fields must contain a
   recognized status string.
   Invalid values are silently rejected.

3. **Section isolation**: Proposals for criteria belonging to a
   different section than the one being edited are ignored.
   For example, proposing `osps_ac_01_01_status=Met` while editing
   the `passing` section will have no effect.
   That's necessary because that ensure that the human user will have
   chance to review the proposal in its proper context.

4. **No direct writes**: Proposed values are loaded into the
   in-memory project object for display in the edit form.
   They are **not** saved to the database until the user explicitly
   submits the form. The user always has the opportunity to review,
   modify, or reject proposals before saving.

## Authentication Flow

The user must be logged in and authorized to edit the project.
When an unauthenticated user visits an edit URL with automation
proposals:

1. The full URL (including all query parameters) is stored in the
   user's session.
2. The user is redirected to the login page.
3. After successful login (via GitHub OAuth or local account), the
   user is redirected back to the original edit URL with all
   automation proposals intact.
4. If the logged-in user is not authorized to edit the project,
   they are redirected to the project's show page with a flash
   message.

## Visual Highlighting

When automation proposals (or internal Chief automation) modify
fields, the edit form highlights them to draw the user's attention:

- **Yellow highlight** (`.highlight-automated`): A field that was
  previously unknown (`?`) and has been filled in with a proposed
  value. This is a helpful suggestion.
- **Orange highlight** (`.highlight-overridden`): A field that
  already had a non-unknown value and has had a forced change, typically
  because a claimed value was manifestly false.
  This needs attention and review.

Highlighting is preserved across "save and continue" operations via
hidden form fields, in case a user decides to review parts of a form.

## Interaction with First-Edit Automation

When a user visits the edit page for a badge level they have not
previously saved, the system runs first-edit automation:

1. Internal "Chief" analysis proposes values for criteria it can
   determine automatically (e.g., by analyzing the project's
   repository URL).
2. URL-based automation proposals are then applied **on top of**
   the Chief analysis results.
3. All changes (from both Chief and URL proposals) are highlighted.

URL proposals take precedence over Chief proposals when both modify
the same field.

## Building Automation Proposal URLs

External tools that want to propose changes should:

1. Know the project's numeric ID (or its URL) and the section to edit.
2. Construct the URL with the appropriate field names and values.
3. URL-encode all values (especially spaces, ampersands, and
   special characters).
4. Use field names exactly as they appear in the criteria YAML files,
   with `_status` or `_justification` appended.

### Example: Tool Proposing License Detection Results

```text
/en/projects/42/passing/edit?floss_license_status=Met&floss_license_justification=Detected+MIT+license+in+LICENSE+file&license=MIT
```

### Example: Tool Proposing OSPS Baseline Results

```text
/en/projects/42/baseline-1/edit?osps_ac_01_01_status=Met&osps_ac_01_01_justification=GitHub+org+enforces+2FA&osps_ac_03_01_status=Met&osps_ac_03_01_justification=Branch+protection+enabled+on+main
```

## Looking Up Projects by URL (`as=edit`)

If an external tool knows a project's repository URL or home page URL
but not its numeric ID, it can use the `as=edit` query on the
projects index to look up and redirect to the edit page:

```text
/en/projects?as=edit&url=ENCODED_URL
/en/projects?as=edit&section=SECTION&url=ENCODED_URL
```

The `section` parameter selects the badge level to edit
(e.g., `passing`, `silver`, `baseline-1`); it defaults to `passing`.
Any additional query parameters (automation proposals) are forwarded
to the edit page with the consumed parameters (`as`, `url`, `section`,
`pq`, `q`) stripped.

For example, to propose license detection results for a project
known only by its repository URL:

```text
/en/projects?as=edit&floss_license_status=Met&url=https%3A%2F%2Fgithub.com%2FORG%2FPROJECT
```

If the URL matches exactly one project, the user is redirected
(HTTP 302) to its edit page. If there are zero or multiple matches,
the normal project list is shown instead.

See [api.md](api.md) for full details on the `as=edit` query
parameter and the redirect behavior.

## Related Documentation

- `docs/api.md` - General documentation on the API, including the
  `as=edit` URL lookup for automation proposals.
- `criteria/criteria.yml` - Metal series criteria definitions.
- `criteria/baseline_criteria.yml` - Baseline (OSPS) criteria
  definitions.
