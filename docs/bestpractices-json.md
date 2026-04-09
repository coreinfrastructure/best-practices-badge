# bestpractices.json

If a project repository has a `.bestproactices.json` file in its top-level
(or in a `.projects.d` subdirectory), that information is used as
proposed answers.

Important: `?` or `"unknown"` means **"I don't know the answer"**
and are **ignored entirely**.
This lets you safely reuse JSON files containing placeholder `?` values

This design allows projects to copy `.bestpractices.json` files from templates
or other projects that are filled with `?` placeholders without accidentally
clearing their existing answers.

## Related Documentation

- `docs/api.md` - General documentation on the API, including the
  `as=edit` URL lookup for automation proposals.
- `criteria/criteria.yml` - Metal series criteria definitions.
- `criteria/baseline_criteria.yml` - Baseline (OSPS) criteria
  definitions.
